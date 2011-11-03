# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP network definitions.
  class Network < AccountResource
    taggable 'nw'

    module IpLeaseMethods
      def add_reserved(ipaddr, description=nil)
        model.create(:network_id=>model_object.id,
                     :ipv4=>ipaddr,
                     :alloc_type=>IpLease::TYPE_RESERVED,
                     :description=>description)
      end
    end
    one_to_many :ip_lease, :extend=>IpLeaseMethods
    many_to_one :vlan_lease
    
    many_to_one :nat_network, :key => :nat_network_id, :class => self
    one_to_many :inside_networks, :key => :nat_network_id, :class => self

    def validate
      super
      
      unless (1..31).include?(self.prefix.to_i)
        errors.add(:prefix, "prefix must be 1-31: #{self.prefix}")
      end

      network_addr = begin
                       IPAddress::IPv4.new("#{self.ipv4_network}/#{self.prefix}").network
                     rescue => e
                       errors.add(:ipv4_network, "Invalid IP address syntax: #{self.ipv4_network}")
                     end
      # validate ipv4 syntax
      if self.ipv4_gw
        begin
          if !network_addr.include?(IPAddress::IPv4.new("#{self.ipv4_gw}"))
            errors.add(:ipv4_gw, "Out of network address range: #{network_addr.to_s}")
          end
        rescue => e
          errors.add(:ipv4_gw, "Invalid IP address syntax: #{self.ipv4_gw}")
        end
      end
      
      if self.dhcp_server
        begin
          if !network_addr.include?(IPAddress::IPv4.new("#{self.dhcp_server}"))
            errors.add(:dhcp_server, "Out of network address range: #{network_addr.to_s}")
          end
        rescue => e
          errors.add(:dhcp_server, "Invalid IP address syntax: #{self.dhcp_server}")
        end
      end
      
    end

    def to_hash
      h = super
      h.delete(:vlan_lease_id)
      h.merge({
                :bandwidth_mark=>self[:id],
                :description=>description.to_s,
                :vlan_id => vlan_lease.nil? ? 0 : vlan_lease.tag_id,
              })
    end

    def before_destroy
      #Make sure no other networks are natted to this one
      Network.filter(:nat_network_id => self[:id]).each { |n|
        n.nat_network_id = nil
        n.save
      }
      
      #Delete all reserved ipleases in this network
      self.ip_lease_dataset.filter(:alloc_type => IpLease::TYPE_RESERVED).each { |i|
        i.destroy
      }
      
      super
    end

    def to_api_document
      to_hash.merge(:id=>self.canonical_uuid)
    end

    def nat_network
      Network.find(:id => self.nat_network_id)
    end

    def ipv4_ipaddress
      IPAddress::IPv4.new("#{self.ipv4_network}/#{self.prefix}").network
    end

    def ipv4_gw_ipaddress
      return nil if self.ipv4_gw.nil?
      IPAddress::IPv4.new("#{self.ipv4_gw}/#{self.prefix}")
    end

    # check if the given IP addess is in the range of this network.
    # @param [String] ipaddr IP address
    def include?(ipaddr)
      ipaddr = ipaddr.is_a?(IPAddress::IPv4) ? ipaddr : IPAddress::IPv4.new(ipaddr)
      self.ipv4_ipaddress.network.include?(ipaddr)
    end

    # register reserved IP address in this network
    def add_reserved(ipaddr)
      add_ip_lease(:ipv4=>ipaddr, :type=>IpLease::TYPE_RESERVED)
    end

    def available_ip_nums
      self.ipv4_ipaddress.hosts.size - self.ip_lease_dataset.count
    end
  end
end
