# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::NetworkModes

  class SecurityGroup
    include Dcmgr::EdgeNetworking::Netfilter::Chains
    include Dcmgr::EdgeNetworking::Netfilter::NetfilterTasks
    include Dcmgr::Helpers::NicHelper

    def init_vnic(vnic_map)
      [
        # chain setup for both layers
        vnic_chains(vnic_map[:uuid]).map {|chain| chain.create},
        forward_chain_jumps(vnic_map[:uuid]),
        nat_prerouting_chain_jumps(vnic_map[:uuid]),
        vnic_main_chain_jumps(vnic_map),
        vnic_main_drop_rules(vnic_map),
        # l2 standard rules
        accept_outbound_arp(vnic_map),
        accept_outbound_ipv4(vnic_map),
        accept_arp_from_gateway(vnic_map),
        accept_arp_from_dns(vnic_map),
        accept_garp_from_gateway(vnic_map),
        accept_arp_reply_with_correct_mac_ip_combo(vnic_map),
        accept_ipv4_protocol(vnic_map),
        # l3 standard rules
        accept_related_established(vnic_map),
        accept_wakame_dns(vnic_map),
        accept_wakame_dhcp_only(vnic_map),
        # address translation rules
        translate_metadata_address(vnic_map)
      ].flatten.compact
    end

    def destroy_vnic(vnic_map)
      [
        forward_chain_jumps(vnic_map[:uuid], "del"),
        nat_prerouting_chain_jumps(vnic_map[:uuid], "del"),
        vnic_chains(vnic_map[:uuid]).map {|chain| chain.destroy}
      ].flatten
    end

    def set_vnic_security_groups(vnic_id, secg_ids)
      [
        I.vnic_l2_iso_chain(vnic_id).flush,
        I.vnic_l2_ref_chain(vnic_id).flush,
        I.vnic_l2_secg_chain(vnic_id).flush,
        I.vnic_l3_iso_chain(vnic_id).flush,
        I.vnic_l3_ref_chain(vnic_id).flush,
        I.vnic_l3_secg_chain(vnic_id).flush,
        O.vnic_l3_secg_chain(vnic_id).flush
      ] +
      secg_ids.map { |secg_id|
        [I.vnic_l2_iso_chain(vnic_id).add_jump(I.secg_l2_iso_chain(secg_id)),
        I.vnic_l2_ref_chain(vnic_id).add_jump(I.secg_l2_ref_chain(secg_id)),
        I.vnic_l2_secg_chain(vnic_id).add_jump(I.secg_l2_rules_chain(secg_id)),
        I.vnic_l3_iso_chain(vnic_id).add_jump(I.secg_l3_iso_chain(secg_id)),
        I.vnic_l3_ref_chain(vnic_id).add_jump(I.secg_l3_ref_chain(secg_id)),
        I.vnic_l3_secg_chain(vnic_id).add_jump(I.secg_l3_rules_chain(secg_id)),
        O.vnic_l3_secg_chain(vnic_id).add_jump(O.secg_l3_rules_chain(secg_id))]
      }.flatten
    end

    #
    # Legacy netfilter code
    #
    def netfilter_all_tasks(vnic,network,friends,security_groups,node)
      tasks = []

      # ***work-around***
      # TODO
      # - multi host nic
      host_addrs = [Dcmgr.conf.logging_service_host_ip].compact

      enable_logging = Dcmgr.conf.packet_drop_log
      ipset_enabled = Dcmgr.conf.use_ipset

      # Drop all traffic that isn't explicitely accepted
      tasks += self.netfilter_drop_tasks(vnic,node)

      # General data link layer tasks
      host_addrs.each {|host_addr|
        tasks << AcceptARPToHost.new(host_addr,vnic[:address],enable_logging,"A arp to_host #{vnic[:uuid]}: ")
      }
      tasks << AcceptARPFromGateway.new(network[:ipv4_gw],vnic[:address],enable_logging,"A arp from_gw #{vnic[:uuid]}: ") unless network[:ipv4_gw].nil?
      tasks << AcceptARPFromDNS.new(network[:dns_server],vnic[:address],enable_logging,"A arp from_dns #{vnic[:uuid]}: ") unless network[:dns_server].nil?
      tasks << DropIpSpoofing.new(vnic[:address],enable_logging,"D arp sp #{vnic[:uuid]}: ")
      tasks << DropMacSpoofing.new(clean_mac(vnic[:mac_addr]),enable_logging,"D ip sp #{vnic[:uuid]}: ")
      tasks << AcceptGARPFromGateway.new(network[:ipv4_gw],enable_logging,"A garp from_gw #{vnic[:uuid]}: ") unless network[:ipv4_gw].nil?
      host_addrs.each {|host_addr|
        tasks << AcceptArpBroadcast.new(host_addr,enable_logging,"A arp bc #{vnic[:uuid]}: ")
      }

      # General ip layer tasks
      tasks << AcceptIcmpRelatedEstablished.new
      tasks << AcceptTcpRelatedEstablished.new
      tasks << AcceptUdpEstablished.new
      #tasks << AcceptAllDNS.new
      tasks << AcceptWakameDNSOnly.new(network[:dns_server]) unless network[:dns_server].nil?
      tasks << AcceptWakameDHCPOnly.new(network[:dhcp_server]) unless network[:dhcp_server].nil?

      # VM isolation based
      tasks += self.netfilter_isolation_tasks(vnic,friends,node)
      tasks += self.netfilter_nat_tasks(vnic,network,node)

      # Logging Service
      tasks += self.netfilter_logging_service_tasks(vnic)

      # Security group rules
      security_groups.each { |secgroup|
        tasks += self.netfilter_secgroup_tasks(vnic, secgroup)

        # Accept ARP from referencing security groups
        ref_vnics = secgroup[:referencers].values.map {|rg| rg.values}.flatten.uniq
        tasks += self.netfilter_arp_isolation_tasks(vnic,ref_vnics,node)
      }

      tasks << AcceptARPReply.new(vnic[:address],clean_mac(vnic[:mac_addr]),enable_logging,"A arp reply #{vnic[:uuid]}: ")
      tasks
    end
  end

end
