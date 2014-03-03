# -*- coding: utf-8 -*-

module Dcmgr
  module Helpers
    module NicHelper
      def find_nic(ifindex = 2)
        ifindex_map = {}
        Dir.glob("/sys/class/net/*/ifindex").each do |ifindex_path|
          device_name = File.split(File.split(ifindex_path).first)[1]
          ifindex_num = File.readlines(ifindex_path).first.strip
          ifindex_map[ifindex_num] = device_name
        end
        #p ifindex_map
        ifindex_map[ifindex.to_s]
      end

      def nic_state(if_name = 'eth0')
        operstate_path = "/sys/class/net/#{if_name}/operstate"
        if File.exists?(operstate_path)
          File.readlines(operstate_path).first.strip
        end
      end

      # This method cleans up ugly mac addressed stored in the dcmgr database.
      # Mac addresses in the database are stored as alphanumeric strings without
      # the : inbetween them. This method properly puts those in there.
      def clean_mac(mac,delim = ':')
        mac.unpack('A2'*6).join(delim)
      end

      def is_natted?(vnic_map)
        not vnic_map[:ipv4][:nat_address].nil?
      end

      def valid_nic?(nic)
        ifindex_path = "/sys/class/net/#{nic}/ifindex"
        if FileTest.exist?(ifindex_path)
          true
        else
          logger.warn("#{nic}: error fetching interface information: Device not found")
          false
        end
      end

      # Lookup bridge device name from given DC network name.
      def bridge_if_name(dc_network_map)
        local_conf = Dcmgr.conf.dc_networks[dc_network_map[:name]]
        if dc_network_map[:vlan_lease]
          dc_network_map[:uuid]
        else
          local_conf.bridge
        end
      end

      def attach_vif_to_bridge(vif, tunctl = nil)
        bridge, cmd, interface = get_bridge_cmd_interface(vif, :attach_vif)

        sh("tunctl -t %s" % [interface]) if tunctl
        sh("/sbin/ip link set %s up" % [interface])
        sh("%s %s %s" % [cmd, bridge, interface])
      end

      def detach_vif_from_bridge(vif, tunctl = nil)
        bridge, cmd, interface = get_bridge_cmd_interface(vif, :detach_vif)

        sh("tunctl -d %s" % [interface]) if tunctl
        sh("/sbin/ip link set %s down" % [interface])
        sh("%s %s %s" % [cmd, bridge, interface])
      end

      def add_bridge_cmd
        get_bridge_cmd(nil, :create_bridge).first
      end

      def get_bridge_cmd_interface(vif, option)
        bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
        [bridge, get_bridge_cmd(vif, option)].flatten
      end

      def get_bridge_cmd(vif, option)
         case Dcmgr.conf.edge_networking
         when 'openvnet' then [vsctl(option), vif && vif_uuid(vif)]
         else                 [brctl(option), vif && vif[:uuid]]
         end
      end

      def vsctl(option)
        list = {:attach => 'add-port', :detach => 'del-port', :create_bridge => 'add-br', :delete_bridge => 'del-br'}
        "#{Dcmgr.conf.vsctl_path} #{list[option]}"
      end

      def brctl(option)
        list = {:attach => 'addif', :detach => 'delif', :create_bridge => 'addbr', :delete_bridge => 'delbr'}
        "#{Dcmgr.conf.brctl_path} #{list[option]}"
      end

      def vif_uuid(vif)
        vif[:uuid].gsub("vif-", "if-")
      end

    end
  end
end
