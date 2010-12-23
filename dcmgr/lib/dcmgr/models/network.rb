# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP network definitions.
  class Network < AccountResource
    taggable 'nw'

    inheritable_schema do
      String :ipv4_gw, :null=>false
      Fixnum :prefix, :null=>false, :default=>24, :unsigned=>true
      String :domain_name
      String :dns_server
      String :dhcp_server
      String :metadata_server
      Fixnum :vlan_lease_id, :null=>false
      Text :description
    end
    with_timestamps

    one_to_many :ip_lease
    many_to_one :vlan_lease

    def validate
      super
      
      # validate ipv4 syntax
      begin
        IPAddress::IPv4.new("#{self.ipv4_gw}")
      rescue => e
        errors.add(:ipv4_gw, "Invalid IP address syntax: #{self.ipv4_gw}")
      end

      unless (1..31).include?(self.prefix.to_i)
        errors.add(:prefix, "prefix must be 1-31: #{self.prefix}")
      end
    end

    def to_hash
      h = self.values.dup
      h.delete(:vlan_lease_id)
      h.merge({
                :description=>description.to_s,
                :vlan_id => vlan_lease.tag_id,
              })
    end

    def ipaddress
      IPAddress::IPv4.new("#{self.ipv4_gw}/#{self.prefix}")
    end

    # check if the given IP addess is in the range of this network.
    # @param [String] ipaddr IP address
    def include?(ipaddr)
      ipaddr = ipaddr.is_a?(IPAddress::IPv4) ? ipaddr : IPAddress::IPv4.new(ipaddr)
      self.ipaddress.network.include?(ipaddr)
    end

    # register reserved IP address in this network
    def add_reserved(ipaddr)
      add_ip_lease(:ipv4=>ipaddr, :type=>IpLease::TYPE_RESERVED)
    end

    def available_ip_nums
      self.ipaddress.hosts.size - self.ip_lease_dataset.count
    end
  end
end
