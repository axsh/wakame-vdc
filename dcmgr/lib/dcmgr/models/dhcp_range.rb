# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # Dynamic IP address range in the network.
  class DhcpRange < BaseNew

    many_to_one :network

    def validate
      super

      if !self.network.ipv4_ipaddress.include?(self.range_begin)
        errors.add(:range_begin, "Out of subnet range: #{self.range_begin}")
      end
      
      if !self.network.ipv4_ipaddress.include?(self.range_end)
        errors.add(:range_begin, "Out of subnet range: #{self.range_end}")
      end
    end

    def range_begin
      IPAddress::IPv4.new("#{super}/#{network.prefix}")
    end

    def range_end
      IPAddress::IPv4.new("#{super}/#{network.prefix}")
    end
  end
end
