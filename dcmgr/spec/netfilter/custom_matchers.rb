# -*- coding: utf-8 -*-


RSpec::Matchers.define :have_applied_vnic do |vnic|
  chain :with_secgs do |secg_array|
    @groups = secg_array
  end

  def l2_chains_for_vnic(vnic_id)
    [
      "vdc_#{vnic_id}_d",
      "vdc_#{vnic_id}_d_standard",
      "vdc_#{vnic_id}_d_isolation",
      "vdc_#{vnic_id}_d_reffers"
    ].sort
  end

  def l3_chains_for_vnic(vnic_id)
    [
      "vdc_#{vnic_id}_d",
      "vdc_#{vnic_id}_d_standard",
      "vdc_#{vnic_id}_d_isolation",
      "vdc_#{vnic_id}_d_reffees",
      "vdc_#{vnic_id}_d_security",
    ].sort
  end

  match do |nfa|
    vnic_id = vnic.canonical_uuid
    @has_l2 = (nfa.all_chain_names("ebtables") & l2_chains_for_vnic(vnic_id)).sort == l2_chains_for_vnic(vnic_id).sort
    @has_l3 = (nfa.all_chain_names("iptables") & l3_chains_for_vnic(vnic_id)).sort == l3_chains_for_vnic(vnic_id).sort

    #TODO: Failure message that shows which chains were missing
    if @groups
      l2iso_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_isolation"}
      l2ref_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_reffers"}
      l3iso_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_isolation"}
      l3ref_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_reffees"}
      l3sec_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_rules"}

      nfa.get_chain("ebtables","vdc_#{vnic_id}_d_isolation").jumps.sort == l2iso_chain_jumps.sort &&
      nfa.get_chain("ebtables","vdc_#{vnic_id}_d_reffers").jumps.sort == l2ref_chain_jumps.sort &&
      nfa.get_chain("iptables","vdc_#{vnic_id}_d_isolation").jumps.sort == l3iso_chain_jumps.sort &&
      nfa.get_chain("iptables","vdc_#{vnic_id}_d_security").jumps.sort == l3sec_chain_jumps.sort &&
      nfa.get_chain("iptables","vdc_#{vnic_id}_d_reffees").jumps.sort == l3ref_chain_jumps.sort &&
      @has_l2 && @has_l3
    else
      @has_l2 && @has_l3
    end
  end
end

RSpec::Matchers.define :have_applied_secg do |secg|
  chain :with_vnics do |vnic_array|
    @vnics = vnic_array
  end

  def l2_chains_for_secg(secg_id)
    ["vdc_#{secg_id}_reffers","vdc_#{secg_id}_isolation"]
  end

  def l3_chains_for_secg(secg_id)
    [
      "vdc_#{secg_id}_rules",
      "vdc_#{secg_id}_reffees",
      "vdc_#{secg_id}_isolation"
    ]
  end

  match do |nfa|
    secg_id = secg.canonical_uuid
    @has_l2 = (nfa.all_chain_names("ebtables") & l2_chains_for_secg(secg_id)).sort == l2_chains_for_secg(secg_id).sort
    @has_l3 = (nfa.all_chain_names("iptables") & l3_chains_for_secg(secg_id)).sort == l3_chains_for_secg(secg_id).sort

    if @vnics
      @vnics.each {|v| raise "VNic '#{v.canonical_uuid}' doesn't have a direct ip lease." if v.direct_ip_lease.first.nil?}
      l2_iso_tasks = @vnics.map {|v| "--protocol arp --arp-opcode Request --arp-ip-src #{v.direct_ip_lease.first.ipv4} -j ACCEPT" }
      l3_iso_tasks = @vnics.map {|v| "-s #{v.direct_ip_lease.first.ipv4} -j ACCEPT"}

      nfa.get_chain("ebtables","vdc_#{secg_id}_isolation").rules.sort == l2_iso_tasks.sort &&
      nfa.get_chain("iptables","vdc_#{secg_id}_isolation").rules.sort == l3_iso_tasks.sort &&
      @has_l2 && @has_l3
    else
      @has_l2 && @has_l3
    end
  end
end

RSpec::Matchers.define :have_nothing_applied do
  match do |nfa|
    nfa.is_empty?("iptables")
    nfa.is_empty?("ebtables")
  end
end
