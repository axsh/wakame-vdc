# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew
    TYPE_AUTO=0
    TYPE_RESERVED=1
    TYPE_MANUAL=2

    TYPE_MESSAGES={
      TYPE_AUTO=>'auto',
      TYPE_RESERVED=>'reserved',
      TYPE_MANUAL=>'manual'
    }
    
    many_to_one :instance_nic
    many_to_one :network

    def validate
      # validate ipv4 syntax
      begin
        addr = IPAddress::IPv4.new("#{self.ipv4}")
        # validate if ipv4 is in the range of network_id.
        unless network.include?(addr)
          errors.add(:ipv4, "IP address #{addr} is out of range: #{network.canonical_uuid})")
        end
      rescue => e
        errors.add(:ipv4, "Invalid IP address syntax: #{self.ipv4} (#{e})")
      end
    end

    # check if the current lease is for NAT outside address lease.
    # @return [TrueClass,FalseClass] return true if the lease is for NAT outside.
    def is_natted?
      instance_nic.network_id != network_id
    end

    # get the lease of NAT outside network.
    # @return [IpLease,nil]
    #    if the IpLease has a pair NAT address it will return
    #    outside IpLease.
    def nat_outside_lease
      if self.instance_nic.nat_network_id
        self.class.find(:instance_nic_id=>self.instance_nic.id, :network_id=>self.instance_nic.nat_network_id)
      else
        nil
      end
    end

    # get the lease of NAT inside network.
    # @return [IpLease,nil] IpLease (outside) will return inside
    #     IpLease.
    def nat_inside_lease
      if self.instance_nic.nat_network_id.nil?
        self.class.find(:instance_nic_id=>self.instance_nic.id, :network_id=>nil)
      else
        nil
      end
    end

    def self.lease(instance_nic, network)
      raise TypeError unless instance_nic.is_a?(InstanceNic)
      raise TypeError unless network.is_a?(Network)

      reserved = []
      reserved << network.ipv4_gw_ipaddress if network.ipv4_gw
      reserved << IPAddress::IPv4.new(network.dhcp_server) if network.dhcp_server
      reserved = reserved.map {|i| i.to_u32 }
      # use SELECT FOR UPDATE to lock rows within same network.
      addrs = network.ipv4_u32_dynamic_range_array - 
        reserved - network.ip_lease_dataset.for_update.all.map {|i| IPAddress::IPv4.new(i.ipv4).to_u32 }
      raise "Run out of dynamic IP addresses from the network segment: #{network.ipv4_network.to_s}/#{network.prefix}" if addrs.empty?
      
      leaseaddr = IPAddress::IPv4.parse_u32(addrs[rand(addrs.size).to_i])
      create(:ipv4=>leaseaddr.to_s, :network_id=>network.id, :instance_nic_id=>instance_nic.id)
    end
  end
end
