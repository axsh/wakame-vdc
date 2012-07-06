# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew
    
    many_to_one :network

    def validate
      # validate ipv4 syntax
      begin
        addr = IPAddress::IPv4::parse_u32(self.ipv4)
        # validate if ipv4 is in the range of network_id.
        unless network.include?(addr)
          errors.add(:ipv4, "IP address #{addr} is out of range: #{network.canonical_uuid})")
        end
        # Set IP address string canonicalized by IPAddress class.
        self.ipv4 = addr.to_i
      rescue => e
        errors.add(:ipv4, "Invalid IP address syntax: #{self.ipv4} (#{e})")
      end
    end


    def self.lease(network_vif, network)
      raise TypeError unless network_vif.is_a?(NetworkVif)
      raise TypeError unless network.is_a?(Network)

      reserved = []
      reserved << network.ipv4_gw_ipaddress if network.ipv4_gw
      reserved << IPAddress::IPv4.new(network.dhcp_server) if network.dhcp_server
      reserved = reserved.map {|i| i.to_u32 }
      # use SELECT FOR UPDATE to lock rows within same network.
      addrs = network.ipv4_u32_dynamic_range_array - 
        reserved - network.network_vif_ip_lease_dataset.alives.for_update.all.map {|i| i.ipv4_i }
      raise "Run out of dynamic IP addresses from the network segment: #{network.ipv4_network.to_s}/#{network.prefix}" if addrs.empty?

      leaseaddr = IPAddress::IPv4.parse_u32(addrs[rand(addrs.size).to_i])
      NetworkVifIpLease.create(:ipv4=>leaseaddr.to_i, :network_id=>network.id, :network_vif_id=>network_vif.id, :description=>leaseaddr.to_s)
    end
  end
end
