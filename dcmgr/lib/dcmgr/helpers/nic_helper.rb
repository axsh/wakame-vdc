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

    end
  end
end
