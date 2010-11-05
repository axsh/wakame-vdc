# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew

    inheritable_schema do
      Fixnum :instance_nic_id, :null=>false
      Fixnum :network_id, :null=>false
      String :ipv4, :size=>50
      
      index :ipv4, {:unique=>true}
    end
    with_timestamps

    many_to_one :instance_nic
    many_to_one :network

    def self.lease(instance_nic)
      raise TypeError unless instance_nic.is_a?(InstanceNic)
      # TODO: consider the case of multiple nics on multiple network.
      network = instance_nic.instance.host_pool.network
      gwaddr = IPAddress::IPv4.new("#{network.ipv4_gw}/#{network.netmask}")
      # use SELECT FOR UPDATE to lock rows within same network.
      addrs = (gwaddr.first.to_u32 .. gwaddr.last.to_u32).to_a -
        [gwaddr.to_u32] - network.ip_lease_dataset.for_update.all.map {|i| IPAddress::IPv4.new(i.ipv4).to_u32 }
      raise "Out of IP address in this network segment: #{gwaddr.network.to_s}/#{gwaddr.prefix}" if addrs.empty?
      
      leaseaddr = IPAddress::IPv4.parse_u32(addrs[rand(addrs.size).to_i])
      create(:ipv4=>leaseaddr.to_s, :network_id=>network.id, :instance_nic_id=>instance_nic.id)
    end
  end
end
