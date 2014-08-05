# -*- coding: utf-8 -*-

module Dcmgr::VNet::NetworkModes

  class SecurityGroup
    include Dcmgr::Helpers::NicHelper
    include Dcmgr::VNet::Tasks

    def netfilter_all_tasks(vnic,network,friends,security_groups,node)
      tasks = []

      # ***work-around***
      # TODO
      # - multi host nic
      host_addrs = [Dcmgr::Configurations.hva.logging_service_host_ip].compact

      enable_logging = Dcmgr::Configurations.hva.packet_drop_log
      ipset_enabled = Dcmgr::Configurations.hva.use_ipset

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

    def netfilter_logging_service_tasks(vnic)
      tasks = []
      logging_service_host_ip = Dcmgr::Configurations.hva.logging_service_host_ip
      logging_service_ip = Dcmgr::Configurations.hva.logging_service_ip
      logging_service_enabled = Dcmgr::Configurations.hva.use_logging_service
      logging_service_port = Dcmgr::Configurations.hva.logging_service_port

      # Logging Service for inside instance.
      if logging_service_enabled
        unless [logging_service_host_ip, logging_service_ip, logging_service_port].any? {|v| v.nil? }
          tasks << TranslateLoggingAddress.new(vnic[:uuid], logging_service_host_ip, logging_service_ip, logging_service_port)
        end
      end
      tasks
    end

    def netfilter_nat_tasks(vnic,network,node)
      tasks = []

      # Nat tasks
      unless vnic[:nat_ip_lease].nil?
        tasks << StaticNatLog.new(vnic[:address], vnic[:nat_ip_lease], "SNAT #{vnic[:uuid]}", "DNAT #{vnic[:uuid]}") if Dcmgr::Configurations.hva.packet_drop_log
        tasks << StaticNat.new(vnic[:address], vnic[:nat_ip_lease], clean_mac(vnic[:mac_addr]))
      end

      #TODO:Move this line out of nat tasks
      tasks << TranslateMetadataAddress.new(vnic[:uuid],network[:metadata_server],network[:metadata_server_port] || 80) unless network[:metadata_server].nil?

      tasks
    end

    def netfilter_isolation_tasks(vnic,friends,node)
      tasks = []
      enable_logging = Dcmgr::Configurations.hva.packet_drop_log
      ipset_enabled = Dcmgr::Configurations.hva.use_ipset

      friend_ips = friends.map { |friend| friend[:address] }.compact

      tasks << AcceptARPFromFriends.new(vnic[:address],friend_ips,enable_logging,"A arp friend #{vnic[:uuid]}")
      tasks << AcceptIpFromFriends.new(friend_ips)

      unless vnic[:nat_ip_lease].nil?
        # Friends don't use NAT, friends talk to each other with their REAL ip addresses.
        # It's a heart warming scene, really
        if ipset_enabled
          # Not implemented yet
          #tasks << ExcludeFromNatIpSet.new(friend_ips,vnic[:address])
        else
          #tasks << ExcludeFromNat.new(friend_ips,vnic[:address])
          tasks << ExcludeFromNat.new(friend_ips,vnic[:address])
        end
      end

      tasks
    end

    def netfilter_secgroup_tasks(vnic, secgroup)
      [Dcmgr::VNet::Tasks::SecurityGroup.new(vnic, secgroup)]
    end

    def netfilter_drop_tasks(vnic,node)
      enable_logging = Dcmgr::Configurations.hva.packet_drop_log

      #TODO: Add logging to ip drops
      [DropIpFromAnywhere.new, DropArpForwarding.new(enable_logging,"D arp #{vnic[:uuid]}: "),DropArpToHost.new]
      #[DropIpFromAnywhere.new]
    end

    def netfilter_arp_isolation_tasks(vnic,friends,node)
      enable_logging = Dcmgr::Configurations.hva.packet_drop_log

      friend_ips = friends.map { |friend| friend[:address] }.compact

      [AcceptARPFromFriends.new(vnic[:address],friend_ips,enable_logging,"A arp friend #{vnic[:uuid]}")]
    end
  end

end
