# -*- coding: utf-8 -*-
require 'ipaddress'
module Dcmgr::Models
  class NetworkVifIpLease < AccountResource
    class RequestError < RuntimeError; end

    TYPE_AUTO=0
    TYPE_RESERVED=1
    TYPE_MANUAL=2

    TYPE_MESSAGES={
      TYPE_AUTO=>'auto',
      TYPE_RESERVED=>'reserved',
      TYPE_MANUAL=>'manual'
    }

    many_to_one :network
    many_to_one :network_vif
    many_to_one :ip_handle

    subset(:alives, {:deleted_at => nil})

    def attach_vif(vif)
      self.network_vif.nil? || raise("Cannot attach IP lease to multiple vifs.")

      self.network_vif = vif
      self.save_changes

      if self.ip_handle && self.ip_handle.expires_at
        self.ip_handle.expires_at = nil
        self.ip_handle.save_changes
      end
      return true
    end

    def detach_vif
      self.network_vif || raise("Cannot detach ip lease that isn't attached to a vif.")

      self.network_vif = nil
      self.save_changes

      if self.ip_handle && self.ip_handle.ip_pool.expire_released
        self.ip_handle.expires_at = Time.now + self.ip_handle.ip_pool.expire_released
        self.ip_handle.save_changes
      end
    end

    # check if the current lease is for NAT outside address lease.
    # @return [TrueClass,FalseClass] return true if the lease is for NAT outside.
    def is_natted?
      network_vif.network_id != network_id
    end

    # get the lease of NAT outside network.
    # @return [IpLease,nil]
    #    if the IpLease has a pair NAT address it will return
    #    outside IpLease.
    def nat_outside_lease
      if self.network_vif.nat_network_id
        self.class.find(:network_vif_id=>self.network_vif.id, :network_id=>self.network_vif.nat_network_id)
      else
        nil
      end
    end

    # get the lease of NAT inside network.
    # @return [IpLease,nil] IpLease (outside) will return inside
    #     IpLease.
    def nat_inside_lease
      if self.network_vif.nat_network_id.nil?
        self.class.find(:network_vif_id=>self.network_vif.id, :network_id=>nil)
      else
        nil
      end
    end

    def ipv4_s
      IPAddress::IPv4::parse_u32(self[:ipv4]).to_s
    end
    alias :ipv4 :ipv4_s

    def ipv4_i
      self[:ipv4]
    end

    def ipv4_ipaddress
      IPAddress::IPv4.new("#{self.ipv4}/#{self.network[:prefix]}")
    end

    #
    # Sequel methods:
    #

    def validate
      # do not run validation if the row is maked as deleted.
      return true if self.deleted_at

      # validate ipv4 syntax
      begin
        addr = IPAddress::IPv4::parse_u32(self.ipv4_i)
        # validate if ipv4 is in the range of network_id.
        unless network.include?(addr)
          errors.add(:ipv4, "IP address #{addr} is out of range: #{network.canonical_uuid})")
        end
        if new?
          unless IpLease.filter(:network_id=>self.network_id, :ipv4=>self.ipv4_i).first.nil?
            errors.add(:ipv4, "IP address #{addr} already exists")
          end

          if self.ip_handle && self.network && !self.ip_handle.ip_pool.has_dc_network(self.network.dc_network)
            errors.add(:ip_handle, "IP pool does not have the right DC network.")
          end
        end

        # Set IP address string canonicalized by IPAddress class.
        self[:ipv4] = addr.to_i
      rescue => e
        errors.add(:ipv4, "Invalid IP address syntax: #{self.ipv4} (#{e})")
      end
    end

    def before_save
      if new?
        IpLease.create(:network_id => self.network_id,
                       :ipv4 => self.ipv4_i,
                       :description => self.ipv4)
      end

      super
    end

    def before_destroy
      IpLease.filter(:network_id=>self.network_id, :ipv4=>self.ipv4_i).destroy
      super
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.is_deleted = self.id
      self.save_changes
    end

  end
end
