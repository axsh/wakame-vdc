# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew
    TYPE_AUTO=0
    TYPE_RESERVED=1
    TYPE_MANUAL=2
    
    inheritable_schema do
      Fixnum :instance_nic_id
      Fixnum :network_id, :null=>false
      String :ipv4, :size=>50
      Fixnum :type, :null=>false, :default=>TYPE_AUTO
      Text :description
      
      index [:network_id, :ipv4], {:unique=>true}
    end
    with_timestamps

    many_to_one :instance_nic
    many_to_one :network

    def validate
      # validate ipv4 syntax
      begin
        addr = IPAddress::IPv4.new("#{self.ipv4}")
        # validate if ipv4 is in the range of network_id.
        unless network.ipaddress.network.include?(addr)
          errors.add(:ipv4, "IP address #{addr} is out of range: #{network.canonical_uuid})")
        end
      rescue => e
        errors.add(:ipv4, "Invalid IP address syntax: #{self.ipv4} (#{e})")
      end
    end

    def self.lease(instance_nic, network)
      raise TypeError unless instance_nic.is_a?(InstanceNic)
      raise TypeError unless network.is_a?(Network)
      
      gwaddr = network.ipaddress
      reserved = [gwaddr]
      reserved = reserved.map {|i| i.to_u32 }
      # use SELECT FOR UPDATE to lock rows within same network.
      addrs = (gwaddr.network.first.to_u32 .. gwaddr.network.last.to_u32).to_a -
        reserved - network.ip_lease_dataset.for_update.all.map {|i| IPAddress::IPv4.new(i.ipv4).to_u32 }
      raise "Out of free IP address in this network segment: #{gwaddr.network.to_s}/#{gwaddr.prefix}" if addrs.empty?
      
      leaseaddr = IPAddress::IPv4.parse_u32(addrs[rand(addrs.size).to_i])
      create(:ipv4=>leaseaddr.to_s, :network_id=>network.id, :instance_nic_id=>instance_nic.id)
    end
  end
end
