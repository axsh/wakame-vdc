# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetworkRoute < BaseNew
    
    many_to_one :outer_network, :key => :outer_network_id, :class => Network
    many_to_one :inner_network, :key => :inner_network_id, :class => Network

    many_to_one :outer_vif, :key => :outer_vif_id, :class => NetworkVif
    many_to_one :inner_vif, :key => :inner_vif_id, :class => NetworkVif

    subset(:alives, {:deleted_at => nil})

    def outer_ipv4
      IPAddress::IPv4::parse_u32(self[:outer_ipv4])
    end

    def inner_ipv4
      IPAddress::IPv4::parse_u32(self[:inner_ipv4])
    end

    def outer_ipv4_s
      IPAddress::IPv4::parse_u32(self[:outer_ipv4]).to_s
    end

    def inner_ipv4_s
      IPAddress::IPv4::parse_u32(self[:inner_ipv4]).to_s
    end

    def outer_ipv4_i
      self[:outer_ipv4]
    end

    def inner_ipv4_i
      self[:inner_ipv4]
    end

    #
    # Sequel methods:
    #

    def validate
      super
      
      self.outer_network.include?(self.outer_ipv4) || errors.add(:outer_ipv4, "Outer IP address out of range: #{self.outer_ipv4_s}")
      self.inner_network.include?(self.inner_ipv4) || errors.add(:inner_ipv4, "Inner IP address out of range: #{self.inner_ipv4_s}")
    end

  end
end
