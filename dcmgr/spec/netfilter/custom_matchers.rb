# -*- coding: utf-8 -*-

module ChainMethods
  def succeed_with(msg)
    @fail_should_not = msg
    true
  end

  def fail_with(msg)
    @fail_should = msg
    false
  end

  def expect_chains(bin, chains)
    actual_chains = @nfa.send(bin).all_chain_names
    if (actual_chains & chains).sort == chains.sort
      succeed_with "There were chains applied that we expected not to.\n
      expected: [#{chains.join(", ")}]\n
      got: [#{actual_chains.join(", ")}]"
    else
      fail_with "The chains we expected weren't applied.\n
      expected: [#{chains.join(", ")}]\n
      got: [#{actual_chains.join(", ")}]"
    end
  end

  def expect_rules_to_contain(bin, chain, rules)
    actual = @nfa.send(bin).get_chain(chain).rules
    expected = rules.sort

    if (actual & expected).sort == expected
      succeed_with "#{bin} chain #{chain} had rules applied that we expected not to be.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    else
      fail_with "#{bin} chain #{chain} didn't apply the rules we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end

  def expect_rules(bin, chain, rules)
    actual = @nfa.send(bin).get_chain(chain).rules.sort
    expected = rules.sort

    if actual == expected
      succeed_with "#{bin} chain '#{chain}' had rules we expected it not to have.\n
      rules: [#{actual.join(", ")}]"
    else
      fail_with "#{bin} chain '#{chain}' didn't have the rules we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end

  def expect_nat_rules(chain, rules)
    actual = @nfa.iptables("nat").get_chain(chain).rules.sort
    expected = rules.sort

    if actual == expected
      succeed_with "iptables nat chain '#{chain}' had rules we expected it not to have.\n
      rules: [#{actual.join(", ")}]"
    else
      fail_with "iptables nat chain '#{chain}' didn't have the rules we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end

  def expect_jumps(bin, chain, targets)
    actual = @nfa.send(bin).get_chain(chain).jumps.sort
    expected = targets.sort

    if actual == expected
      succeed_with "#{bin} chain '#{chain}' had jumps we expected it not to have.\n
      jumps: [#{actual.join(", ")}]"
    else
      fail_with "#{bin} chain '#{chain}' didn't have the jumps we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end
end

RSpec::Matchers.define :have_applied_vnic do |vnic|
  include ChainMethods

  def l2_inbound_chains_for_vnic
    [
      "vdc_#{@vnic_id}_d",
      "vdc_#{@vnic_id}_d_isolation",
      "vdc_#{@vnic_id}_d_reffers",
      "vdc_#{@vnic_id}_d_standard"
    ]
  end

  def l3_inbound_chains_for_vnic
    [
      "vdc_#{@vnic_id}_d",
      "vdc_#{@vnic_id}_d_isolation",
      "vdc_#{@vnic_id}_d_reffees",
      "vdc_#{@vnic_id}_d_security",
      "vdc_#{@vnic_id}_d_standard"
    ]
  end

  def l2_outbound_chains_for_vnic
    [
      "vdc_#{@vnic_id}_s",
      "vdc_#{@vnic_id}_s_standard"
    ]
  end

  def l3_outbound_chains_for_vnic
    [
      "vdc_#{@vnic_id}_s",
      "vdc_#{@vnic_id}_s_security"
    ]
  end

  def l2_chains_for_vnic
    l2_inbound_chains_for_vnic + l2_outbound_chains_for_vnic
  end

  def l3_chains_for_vnic
    l3_inbound_chains_for_vnic + l3_outbound_chains_for_vnic
  end

  def l2_inbound_main_chain_jumps
    [
      "vdc_#{@vnic_id}_d_isolation",
      "vdc_#{@vnic_id}_d_reffers",
      "vdc_#{@vnic_id}_d_standard",
      "DROP"
    ]
  end

  def l3_inbound_main_chain_jumps
    [
      "vdc_#{@vnic_id}_d_isolation",
      "vdc_#{@vnic_id}_d_reffees",
      "vdc_#{@vnic_id}_d_security",
      "vdc_#{@vnic_id}_d_standard",
      "DROP"
    ]
  end

  def l2_outbound_main_chain_jumps
    [
      "vdc_#{@vnic_id}_s_standard"
    ]
  end

  def l3_outbound_main_chain_jumps
    [
      "vdc_#{@vnic_id}_s_security"
    ]
  end

  def group_chains(suffix)
    @groups.map {|g| "vdc_#{g.canonical_uuid}_#{suffix}" }
  end

  def l2_inbound_stnd_rules_for_vnic
    vnic_ip = @vnic.direct_ip_lease.first.ipv4
    gw_ip = @vnic.network && @vnic.network.ipv4_gw
    dns_server = @vnic.network && @vnic.network.dns_server
    rules = []

    rules << "--protocol arp --arp-opcode Request --arp-ip-src=#{gw_ip} --arp-ip-dst=#{vnic_ip} -j ACCEPT" if gw_ip
    rules << "--protocol arp --arp-opcode Request --arp-ip-src=#{dns_server} --arp-ip-dst=#{vnic_ip} -j ACCEPT" if dns_server
    rules << "--protocol arp --arp-gratuitous --arp-ip-src=#{gw_ip} -j ACCEPT" if gw_ip
    rules << "--protocol arp --arp-opcode Reply --arp-ip-dst=#{vnic_ip} --arp-mac-dst=#{@vnic.pretty_mac_addr} -j ACCEPT"
    rules << "--protocol IPv4 -j ACCEPT"

    rules
  end

  def l3_inbound_stnd_rules_for_vnic
    dns_server = @vnic.network && @vnic.network.dns_server
    dhcp_server = @vnic.network && @vnic.network.dhcp_server
    rules = []

    rules << "-m state --state RELATED,ESTABLISHED -j ACCEPT"
    rules << "-p udp -d #{dns_server} --dport 53 -j ACCEPT" if dns_server
    rules << "-p udp ! -s #{dhcp_server} --sport 67:68 -j DROP" if dhcp_server
    rules << "-p udp -s #{dhcp_server} --sport 67:68 -j ACCEPT" if dhcp_server

    rules
  end

  def l3_address_translation_rules
    metadata_server = @vnic.network && @vnic.network.metadata_server
    metadata_server_port = @vnic.network && @vnic.network.metadata_server_port

    metadata_server.nil? ? [] : ["-d 169.254.169.254 -p tcp --dport 80 -j DNAT --to-destination #{@vnic.network.metadata_server}:#{@vnic.network.metadata_server_port}"]
  end

  chain :with_secgs do |secg_array|
    @groups = secg_array
  end

  match do |nfa|
    @nfa = nfa
    @vnic = vnic
    @vnic_id = vnic.canonical_uuid

    expect_chains("ebtables", l2_chains_for_vnic) &&
    expect_rules_to_contain("ebtables", "FORWARD", ["-o #{@vnic_id} -j vdc_#{@vnic_id}_d", "-i #{@vnic_id} -j vdc_#{@vnic_id}_s"]) &&
    expect_jumps("ebtables", "vdc_#{@vnic_id}_d", l2_inbound_main_chain_jumps) &&
    expect_jumps("ebtables", "vdc_#{@vnic_id}_s", l2_outbound_main_chain_jumps) &&
    expect_rules("ebtables", "vdc_#{@vnic_id}_d_standard", l2_inbound_stnd_rules_for_vnic) &&

    expect_chains("iptables", l3_chains_for_vnic) &&
    expect_rules_to_contain("iptables", "FORWARD", [
      "-m physdev --physdev-is-bridged --physdev-out #{@vnic_id} -j vdc_#{@vnic_id}_d",
      "-m physdev --physdev-is-bridged --physdev-in #{@vnic_id} -j vdc_#{@vnic_id}_s"
    ]) &&
    expect_jumps("iptables", "vdc_#{@vnic_id}_s", l3_outbound_main_chain_jumps) &&
    expect_jumps("iptables", "vdc_#{@vnic_id}_d", l3_inbound_main_chain_jumps) &&
    expect_rules("iptables", "vdc_#{@vnic_id}_d_standard", l3_inbound_stnd_rules_for_vnic) &&
    expect_nat_rules("vdc_#{@vnic_id}_s_dnat", l3_address_translation_rules) &&

    ( @groups.nil? || (
      expect_jumps("ebtables", "vdc_#{@vnic_id}_d_isolation", group_chains("isolation")) &&
      expect_jumps("ebtables", "vdc_#{@vnic_id}_d_reffers", group_chains("reffers")) &&
      expect_jumps("iptables", "vdc_#{@vnic_id}_d_isolation", group_chains("isolation")) &&
      expect_jumps("iptables", "vdc_#{@vnic_id}_d_security", group_chains("d_rules")) &&
      expect_jumps("iptables", "vdc_#{@vnic_id}_d_reffees", group_chains("reffees")) &&
      expect_jumps("iptables", "vdc_#{@vnic_id}_s_security", group_chains("s_rules"))
    ))
  end

  failure_message_for_should {|nfa| @fail_should}
  failure_message_for_should_not {|nfa| @fail_should_not}
end

RSpec::Matchers.define :have_applied_secg do |secg|
  include ChainMethods

  def l2_chains_for_secg(secg_id)
    ["vdc_#{secg_id}_reffers", "vdc_#{secg_id}_isolation"]
  end

  def l3_chains_for_secg(secg_id)
    [
      "vdc_#{secg_id}_s_rules",
      "vdc_#{secg_id}_d_rules",
      "vdc_#{secg_id}_reffees",
      "vdc_#{secg_id}_isolation"
    ]
  end

  def l2_iso_rules
    @vnics.map {|v| "--protocol arp --arp-opcode Request --arp-ip-src #{v.direct_ip_lease.first.ipv4} -j ACCEPT" }
  end

  def l3_iso_rules
    @vnics.map {|v| "-s #{v.direct_ip_lease.first.ipv4} -j ACCEPT"}
  end

  chain :with_vnics do |vnic_array|
    @vnics = vnic_array
  end

  match do |nfa|
    @nfa = nfa
    secg_id = secg.canonical_uuid

    expect_chains("ebtables", l2_chains_for_secg(secg_id)) &&
    expect_chains("iptables", l3_chains_for_secg(secg_id)) &&
    ( @vnics.nil? || (
      @vnics.each {|v| raise "VNic '#{v.canonical_uuid}' doesn't have a direct ip lease." if v.direct_ip_lease.first.nil?}
      expect_rules("ebtables", "vdc_#{secg_id}_isolation", l2_iso_rules) &&
      expect_rules("iptables", "vdc_#{secg_id}_isolation", l3_iso_rules)
    ))
  end

  failure_message_for_should {|nfa| @fail_should}
  failure_message_for_should_not {|nfa| @fail_should_not}
end

RSpec::Matchers.define :have_nothing_applied do
  match do |nfa|
    !nfa.iptables.has_custom_chains? &&
    !nfa.ebtables.has_custom_chains? &&
    nfa.iptables.get_chain("FORWARD").jumps == [] &&
    nfa.iptables.get_chain("FORWARD").rules == [] &&
    nfa.ebtables.get_chain("FORWARD").jumps == [] &&
    nfa.ebtables.get_chain("FORWARD").rules == []
  end
end
