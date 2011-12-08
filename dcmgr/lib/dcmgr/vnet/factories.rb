# -*- coding: utf-8 -*-

module Dcmgr
  module Vnet
    # This module stores the factories. It is their job to read config files etc. to decide which implementation to use.
    module Factories
      
      class ControllerFactory
        def self.create_controller(node)
          NetfilterController.new(node)
        end
      end
      
      class IsolatorFactory
        def self.create_isolator
          #SecurityGroupIsolator.new
          DummyIsolator.new
        end
      end
      
      class TaskManagerFactory
        def self.create_task_manager(node)
          manager = VNicProtocolTaskManager.new
          manager.enable_ebtables = node.manifest.config.enable_ebtables
          manager.enable_iptables = node.manifest.config.enable_iptables
          manager.verbose_commands = node.manifest.config.verbose_netfilter
          
          manager
        end
      end
      
      class TaskFactory
        extend Dcmgr::Helpers::NicHelper

        #Returns the netfilter tasks required for this vnic
        # The _friends_ parameter is an array of vnic_maps that should not be isolated from _vnic_
        def self.create_tasks_for_vnic(vnic,friends,node)
          tasks = []

          host_addr = Isono::Util.default_gw_ipaddr
          enable_logging = node.manifest.config.packet_drop_log
          ipset_enabled = node.manifest.config.use_ipset
          
          friend_ips = friends.map {|vnic_map| vnic_map[:ipv4][:address]}
          
          # Nat tasks
          if is_natted? vnic
            tasks << StaticNatLog.new(vnic[:ipv4][:address], vnic[:ipv4][:nat_address], "SNAT #{vnic[:uuid]}", "DNAT #{vnic[:uuid]}") if node.manifest.config.packet_drop_log
            tasks << StaticNat.new(vnic[:ipv4][:address], vnic[:ipv4][:nat_address], clean_mac(vnic[:mac_addr]))
            
            # Exclude instances in the same security group form using nat
            if ipset_enabled
              tasks << ExcludeFromNatIpSet(friend_ips,vnic[:ipv4][:address])
            else
              tasks << ExcludeFromNat(friend_ips,vnic[:ipv4][:address])
            end
          end
          
          # General data link layer tasks
          tasks << AcceptArpBroadcast.new(host_addr,enable_logging,"A arp bc #{vnic[:uuid]}: ")
          tasks << AntiIpSpoofing.new(vnic[:ipv4][:address],enable_logging,"D arp sp #{vnic[:uuid]}: ")
          tasks << DropMacSpoofing.new(clean_mac(vnic[:mac_addr]),enable_logging,"D ip sp #{vnic[:uuid]}: ")
          tasks << AcceptARPToHost.new(host_addr,vnic[:ipv4][:address],enable_logging,"A arp to_host #{vnic[:uuid]}: ")
          
          # General ip layer tasks
          tasks << AcceptIcmpRelatedEstablished.new
          tasks << AcceptTcpRelatedEstablished.new
          tasks << AcceptUdpEstablished.new
          #tasks << AcceptWakameDNSOnly.new(vnic[:ipv4][:network][:dns_server])
          tasks << AcceptAllDNS.new
          tasks << AcceptWakameDHCPOnly.new(vnic[:ipv4][:network][:dhcp_server])
          # Metadata address translation poses a bit of a problem on non natted machines
          # Nat chains don't get created and the taskmanager tries to place it in a non existent chain
          #TODO: FIX!
          #tasks << TranslateMetadataAddress.new(vnic[:ipv4][:network][:metadata_server],vnic[:ipv4][:network][:metadata_server_port])
          tasks << AcceptIpToAnywhere.new
          
          # Security group tasks
          #tasks << SecurityGroup(....)
          
          # VM isolation based on same security group
          #tasks << AcceptARPFromFriends.new(vnic[:ipv4][:address],friend_ips,enable_logging,"A arp friend #{vnic.uuid}") # <--- constructor values not filled in yet
          #tasks << AcceptIpFromFriends(friend_ips)
          
          # Accept ip traffic from the gateway that isn't blocked by other tasks
          tasks << AcceptIpFromGateway.new(vnic[:ipv4][:network][:ipv4_gw])
                    
          # Drop any other incoming traffic
          # MAKE SURE THIS TASK IS ALWAYS EXECUTED LAST OR I WILL KILL YOU
          tasks << DropIpFromAnywhere.new #<-- has no arguments
          tasks << DropArpForwarding.new(enable_logging,"D arp #{vnic[:uuid]}: ")
          
          tasks
        end
      end
      
    end
  end
end
