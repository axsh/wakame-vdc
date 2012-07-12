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
      latest_ip = network.network_vif_ip_lease_dataset.alives.filter(:updated_at =>latest).filter(:alloc_type =>NetworkVifIpLease::TYPE_AUTO).map {|i| i.ipv4}
      if latest_ip.empty?
        ipaddr = nil
      else
        ipaddr = IPAddress::IPv4.new("#{latest_ip.first}/#{network[:prefix]}").to_i
      end
      leaseaddr = case network[:ip_assignment]
                  when "asc"
                    ip = get_lease_address(network, ipaddr, nil)
                    ip = get_lease_address(network, nil, ipaddr) if ip.nil?
                    ip
                  when "desc"
                    ip = get_lease_address(network, nil, ipaddr)
                    ip = get_lease_address(network, ipaddr, nil) if ip.nil?
                    ip
                  end
      raise "Run out of dynamic IP addresses from the network segment: #{network.ipv4_network.to_s}/#{network.prefix}" if leaseaddr.nil?

      leaseaddr = IPAddress::IPv4.parse_u32(leaseaddr)
      NetworkVifIpLease.create(:ipv4=>leaseaddr.to_i, :network_id=>network.id, :network_vif_id=>network_vif.id, :description=>leaseaddr.to_s)
    end

    def self.get_lease_address(network, from_ipaddr, to_ipaddr)
      leaseaddr = nil
      ranges = network.dhcp_range_dataset
      ranges = case network[:ip_assignment]
               when "asc"
                 ranges.order(:range_begin.asc)
               when "desc"
                 ranges.order(:range_end.desc)
               end
      ranges.all.each {|i|
        unless from_ipaddr.nil?
          next if from_ipaddr >= i.range_end.to_i
          f = from_ipaddr
          f = i.range_begin.to_i if from_ipaddr <= i.range_begin.to_i
        else
          f = i.range_begin.to_i
        end
        unless to_ipaddr.nil?
          next if to_ipaddr <= i.range_begin.to_i
          t = to_ipaddr
          t = i.range_end.to_i if to_ipaddr >= i.range_end.to_i
        else
          t = i.range_end.to_i
        end
        begin
          leaseaddr = i.available_ip(f, t)
          check_ip = IPAddress::IPv4.parse_u32(leaseaddr)
          if [0,255].member?(check_ip[3])
            network.network_vif_ip_lease_dataset.add_reserved(check_ip.to_s)
            case network[:ip_assignment]
            when "asc"
              f = check_ip.to_i
            when "desc"
              t = check_ip.to_i
            end
          end
          break if leaseaddr.nil?
        end while self.find(:ipv4=>leaseaddr)
        break unless leaseaddr.nil?
      }
      leaseaddr
    end
  end
end
