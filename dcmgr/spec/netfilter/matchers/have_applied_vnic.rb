# -*- coding: utf-8 -*-

module DcmgrSpec::Netfilter::Matchers
  RSpec::Matchers.define :have_applied_vnic do |vnic|
    include ChainMethods

    def l2_inbound_chains_for_vnic
      [
        "vdc_#{@vnic_id}_d",
        "vdc_#{@vnic_id}_d_isolation",
        "vdc_#{@vnic_id}_d_ref",
        "vdc_#{@vnic_id}_d_rules",
        "vdc_#{@vnic_id}_d_standard",
      ]
    end

    def l3_inbound_chains_for_vnic
      [
        "vdc_#{@vnic_id}_d",
        "vdc_#{@vnic_id}_d_isolation",
        "vdc_#{@vnic_id}_d_ref",
        "vdc_#{@vnic_id}_d_rules",
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
        "vdc_#{@vnic_id}_s_rules"
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
        "vdc_#{@vnic_id}_d_ref",
        "vdc_#{@vnic_id}_d_rules",
        "vdc_#{@vnic_id}_d_standard",
        "DROP"
      ]
    end

    def l3_inbound_main_chain_jumps
      [
        "vdc_#{@vnic_id}_d_isolation",
        "vdc_#{@vnic_id}_d_ref",
        "vdc_#{@vnic_id}_d_rules",
        "vdc_#{@vnic_id}_d_standard",
        "DROP"
      ]
    end

    def l2_outbound_main_chain_jumps
      [
        "vdc_#{@vnic_id}_s_standard",
        "DROP"
      ]
    end

    def l3_outbound_main_chain_jumps
      [
        "vdc_#{@vnic_id}_s_rules"
      ]
    end

    def group_chains(suffix)
      @groups.map {|g| "vdc_#{g.canonical_uuid}_#{suffix}" }
    end

    def vnic_ip
      @vnic.direct_ip_lease.first.ipv4
    end

    def vnic_mac
      @vnic.pretty_mac_addr
    end

    def dns_server
      @vnic.network && @vnic.network.dns_server
    end

    def metadata_server
      @vnic.network && @vnic.network.metadata_server
    end

    def metadata_server_port
      @vnic.network && @vnic.network.metadata_server_port
    end

    def l2_inbound_stnd_rules_for_vnic
      gw_ip = @vnic.network && @vnic.network.ipv4_gw

      accept_arp_from_ip = lambda do |ip_src|
        "--protocol arp --arp-opcode Request --arp-ip-src=#{ip_src} --arp-ip-dst=#{vnic_ip} -j ACCEPT"
      end

      rules = []

      rules << accept_arp_from_ip.call(gw_ip) if gw_ip
      rules << accept_arp_from_ip.call(dns_server) if dns_server
      rules << accept_arp_from_ip.call(metadata_server) if metadata_server
      rules << "--protocol arp --arp-gratuitous --arp-ip-src=#{gw_ip} -j ACCEPT" if gw_ip
      rules << "--protocol arp --arp-opcode Reply --arp-ip-dst=#{vnic_ip} --arp-mac-dst=#{vnic_mac} -j ACCEPT"
      rules << "--protocol IPv4 -j ACCEPT"

      rules
    end

    def l2_outbound_stnd_rules_for_vnic
      [
        "-p ARP --arp-ip-src #{vnic_ip} --arp-mac-src #{vnic_mac} -j ACCEPT",
        "-p IPv4 --among-src #{vnic_mac}=#{vnic_ip}, -j ACCEPT"
      ]
    end

    def l3_inbound_stnd_rules_for_vnic
      dhcp_server = @vnic.network && @vnic.network.dhcp_server
      rules = []

      rules << "-m state --state RELATED,ESTABLISHED -j ACCEPT"
      rules << "-p udp -d #{dns_server} --dport 53 -j ACCEPT" if dns_server
      rules << "-p udp ! -s #{dhcp_server} --sport 67:68 -j DROP" if dhcp_server
      rules << "-p udp -s #{dhcp_server} --sport 67:68 -j ACCEPT" if dhcp_server
      rules << "-p tcp -s #{metadata_server} --sport #{metadata_server_port} -j ACCEPT" if metadata_server

      rules
    end

    def l3_address_translation_rules
      if metadata_server.nil?
        []
      else
        srv = @vnic.network.metadata_server
        prt = @vnic.network.metadata_server_port
        ["-d 169.254.169.254 -p tcp --dport 80 -j DNAT --to-destination #{srv}:#{prt}"]
      end
    end

    chain :with_secgs do |secg_array|
      @groups = secg_array
    end

    match do |nfa|
      @nfa = nfa
      @vnic = vnic
      @vnic_id = vnic.canonical_uuid

      #
      # L2 standard stuff
      #
      expect_chains("ebtables", l2_chains_for_vnic) &&
      expect_rules_to_contain("ebtables", "FORWARD", [
        "-o #{@vnic_id} -j vdc_#{@vnic_id}_d",
        "-i #{@vnic_id} -j vdc_#{@vnic_id}_s"
      ]) &&
      expect_jumps("ebtables", "vdc_#{@vnic_id}_d", l2_inbound_main_chain_jumps) &&
      expect_jumps("ebtables", "vdc_#{@vnic_id}_s", l2_outbound_main_chain_jumps) &&
      expect_rules("ebtables", "vdc_#{@vnic_id}_d_standard", l2_inbound_stnd_rules_for_vnic) &&

      #
      # L3 standard stuff
      #
      expect_chains("iptables", l3_chains_for_vnic) &&
      expect_rules_to_contain("iptables", "FORWARD", [
        "-m physdev --physdev-is-bridged --physdev-out #{@vnic_id} -j vdc_#{@vnic_id}_d",
        "-m physdev --physdev-is-bridged --physdev-in #{@vnic_id} -j vdc_#{@vnic_id}_s"
      ]) &&
      expect_jumps("iptables", "vdc_#{@vnic_id}_s", l3_outbound_main_chain_jumps) &&
      expect_jumps("iptables", "vdc_#{@vnic_id}_d", l3_inbound_main_chain_jumps) &&
      expect_rules("iptables", "vdc_#{@vnic_id}_d_standard", l3_inbound_stnd_rules_for_vnic) &&
      expect_nat_rules("vdc_#{@vnic_id}_s_dnat", l3_address_translation_rules) &&

      #
      # Security Groups stuff
      #
      ( @groups.nil? || (
        expect_jumps("ebtables", "vdc_#{@vnic_id}_d_isolation", group_chains("isolation")) &&
        expect_jumps("ebtables", "vdc_#{@vnic_id}_d_ref", group_chains("ref")) &&
        expect_jumps("ebtables", "vdc_#{@vnic_id}_d_rules", group_chains("d_rules")) &&
        expect_jumps("iptables", "vdc_#{@vnic_id}_d_isolation", group_chains("isolation")) &&
        expect_jumps("iptables", "vdc_#{@vnic_id}_d_rules", group_chains("d_rules")) &&
        expect_jumps("iptables", "vdc_#{@vnic_id}_d_ref", group_chains("ref")) &&
        expect_jumps("iptables", "vdc_#{@vnic_id}_s_rules", group_chains("s_rules"))
      ))
    end

    failure_message {|nfa| @fail_should}
    failure_message_when_negated {|nfa| @fail_not_to}
  end
end
