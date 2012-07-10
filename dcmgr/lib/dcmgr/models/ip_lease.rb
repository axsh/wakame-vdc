# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew
    
    many_to_one :network

    def_dataset_method(:leased_ip_bound_lease) {
        select(:ip_leases__ipv4, :prev__ipv4___prev, :follow__ipv4___follow).join_table(:left, :ip_leases___prev, :ip_leases__ipv4=>:prev__ipv4 +1).join_table(:left, :ip_leases___follow, :ip_leases__ipv4=>:follow__ipv4 - 1).filter({:prev__ipv4=>nil} | {:follow__ipv4=>nil})
    }

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

      latest = network.network_vif_ip_lease_dataset.alives.max(:updated_at)
      latest_ip = network.network_vif_ip_lease_dataset.alives.filter(:updated_at =>latest).filter(:alloc_type =>NetworkVifIpLease::TYPE_AUTO).map {|i| i.ipv4_i}
      if latest_ip.empty?
        ipaddr = nil
      else
        ipaddr = latest_ip.first
      end

      leaseaddr = nil
      network.dhcp_range_dataset.all.each {|i|
        begin
          leaseaddr = i.available_ip(ipaddr)
          unless leaseaddr.nil?
            ipaddr = IPAddress::IPv4.parse_u32(leaseaddr)
            if network[:ipv4_gw] == ipaddr.to_s ||
                network[:dns_server] == ipaddr.to_s ||
                network[:dhcp_server] == ipaddr.to_s ||
                network[:metadata_server] == ipaddr.to_s

              network.network_vif_ip_lease_dataset.add_reserved(ipaddr.to_s)
              ipaddr = ipaddr.to_i
            end
          end
          break if leaseaddr.nil?
        end while self.find(:ipv4=>leaseaddr)
        break unless leaseaddr.nil?
      }
      raise "Run out of dynamic IP addresses from the network segment: #{network.ipv4_network.to_s}/#{network.prefix}" if leaseaddr.nil?

      leaseaddr = IPAddress::IPv4.parse_u32(leaseaddr)
      NetworkVifIpLease.create(:ipv4=>leaseaddr.to_i, :network_id=>network.id, :network_vif_id=>network_vif.id, :description=>leaseaddr.to_s)
    end
  end
end
