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
        errors.add(:range_end, "Out of subnet range: #{self.range_end}")
      end

      if !(self.range_begin <= self.range_end)
        # swap values.
        t = self[:range_end]
        self[:range_end] = self[:range_begin]
        self[:range_begin] = t
      end
    end

    def range_begin
      IPAddress::IPv4.new("#{super}/#{network.prefix}")
    end

    def range_end
      IPAddress::IPv4.new("#{super}/#{network.prefix}")
    end

    def start_range
      if self.range_begin.network?
        self.range_begin.first.to_i
      else
        self.range_begin.to_i
      end
    end

    def end_range
      if (self.range_end)[3] == 255
        self.range_end.last.to_i
      else
        self.range_end.to_i
      end
    end

    def leased_ips
      IpLease.where(:ip_leases__network_id=>self.network_id).filter(:ip_leases__ipv4=>start_range..end_range)
    end

    def available_ip
      boundaries = leased_ips.leased_ip_bound_lease.limit(2).all
      ipaddr = case boundaries.size
               when 1
                 boundary = boundaries.first
                 if boundary[:prev].nil?
                   if boundary[:ipv4] != start_range
                     start_range
                   else
                     boundary[:ipv4] + 1
                   end
                 end
               when 2
                 ip = nil
                 boundaries.each {|i|
                   if i[:prev].nil? and i[:follow].nil?
                     if i[:ipv4] != start_range
                       ip = start_range
                       break
                     else
                       ip = i[:ipv4] + 1
                       break
                     end
                   elsif i[:follow].nil?
                     ip = i[:ipv4] + 1
                     if ip <= end_range
                       ip
                       break
                     end
                   end
                 }
                 
                 ip
               else 
                 start_range
               end

      IPAddress::IPv4.parse_u32(ipaddr)
    end

    def leased_ranges
      ary = []
      leased_ips.leased_ip_bound_lease.all.map {|i|
        ipaddr = i[:ipv4]
        ary.push([ipaddr]) if i[:prev].nil?
        ary.last.push(ipaddr) if i[:follow].nil?
      }

      ary
    end

    def not_leased_ranges
      ary = []
      leased_ips.leased_ip_bound_lease.all.map {|i|
        ipaddr = i[:ipv4]
        ary.push([ipaddr-1]) if i[:prev].nil?
        ary.last.push(ipaddr+1) if i[:follow].nil?
      }
      ary.first.unshift(start_range)
      ary.last.push(end_range)

      ary
    end
  end
end
