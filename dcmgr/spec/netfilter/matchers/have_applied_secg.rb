# -*- coding: utf-8 -*-

module DcmgrSpec::Netfilter::Matchers
  RSpec::Matchers.define :have_applied_secg do |secg|
    include ChainMethods

    def l2_chains_for_secg(secg_id)
      ["vdc_#{secg_id}_ref", "vdc_#{secg_id}_isolation"]
    end

    def l3_chains_for_secg(secg_id)
      [
        "vdc_#{secg_id}_s_rules",
        "vdc_#{secg_id}_d_rules",
        "vdc_#{secg_id}_ref",
        "vdc_#{secg_id}_isolation"
      ]
    end

    def l2_rule_arp
      source_ips = @rules.map { |rule| rule.split("-s")[1].split(" ")[0] }.uniq
      source_ips.map {|ip| "--protocol arp --arp-opcode Request --arp-ip-src=#{ip} -j ACCEPT"}
    end

    def l2_iso_rules
      @vnics.map {|v| "--protocol arp --arp-opcode Request --arp-ip-src=#{v.direct_ip_lease.first.ipv4} -j ACCEPT" }
    end

    def l2_reffer_rules
      @reffers.map {|v| "--protocol arp --arp-opcode Request --arp-ip-src=#{v.direct_ip_lease.first.ipv4} -j ACCEPT" }
    end

    def l3_iso_rules
      @vnics.map {|v| "-s #{v.direct_ip_lease.first.ipv4} -j ACCEPT"}
    end

    chain :with_vnics do |vnic_array|
      @vnics = vnic_array
    end

    chain :with_rules do |rules_array|
      @rules = rules_array
    end

    chain :with_referencees do |reffer_array|
      @reffers = reffer_array
    end

    chain :with_reference_rules do |rules_array|
      @ref_rules = rules_array
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
      )) &&
      ( @rules.nil? || (
        expect_rules("iptables", "vdc_#{secg_id}_d_rules", @rules) &&
        expect_rules("ebtables", "vdc_#{secg_id}_d_rules", l2_rule_arp)
      )) &&
      ( @reffers.nil? || (
        expect_rules("ebtables", "vdc_#{secg_id}_ref", l2_reffer_rules)
      )) &&
      ( @ref_rules.nil? || (
        expect_rules("iptables", "vdc_#{secg_id}_ref", @ref_rules)
      ))
    end

    failure_message_for_should {|nfa| @fail_should}
    failure_message_for_should_not {|nfa| @fail_should_not}
  end
end
