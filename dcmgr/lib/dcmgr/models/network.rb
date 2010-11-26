# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # Network definitions in the DC.
  class Network < BaseNew

    inheritable_schema do
      String :name, :null=>false
      String :ipv4_gw, :null=>false
      Fixnum :prefix, :null=>false, :default=>24, :unsigned=>true
      String :domain_name, :null=>false
      String :dns_server, :null=>false
      String :dhcp_server, :null=>false
      String :dhcp_start_ip
      Fixnum :dhcp_range, :unsigned=>true
      String :metadata_server
      Text :description
      index :name, {:unique=>true}
    end
    with_timestamps

    many_to_one :host_pool
    one_to_many :ip_lease

    def validate
      super
      errors.add(:prefix, "prefix must be >= 32: #{self.prefix}") if self.prefix > 32
      
      if self.dhcp_start_ip
        start = IPAddress("#{dhcp_start_ip}/#{prefix}")
        gw = IPAddress("#{ipv4_gw}/#{prefix}")
        if start.subnet != gw.subnet
          errors.add(:ipv4_gw, "ipv4_gw (#{ipv4_gw}/#{prefix}) is mismatch with dhcp_start_ip (#{dhcp_start_ip}/#{prefix})")
        end
        range_last = IPAddress::IPv4.parse_u32(start.to_u32 + self.dhcp_range, self.prefix)
        if start.last < range_last
          errors.add(:dhcp_range, "dhcp_range is too long: >#{start.last.to_u32 - start.to_u32}")
        end
      end
    end

    def to_hash
      values.dup.merge({:description=>description.to_s})
    end

    def lease_dynamic?
      !self.dhcp_start_ip.nil?
    end
    
    def dhcp_lease_range
      start_ip = IPAddress("#{dhcp_start_ip}/#{prefix}")
      last_ip = IPAddress::IPv4.parse_u32(start_ip.to_u32 + self.dhcp_range, self.prefix)
      [start_ip, last_ip]
    end
    
  end
end
