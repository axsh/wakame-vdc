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

    def leased_ips(first, last)
      IpLease.where(:ip_leases__network_id=>self.network_id).filter(:ip_leases__ipv4=>first..last)
    end

    def available_ip(addr=nil)
      ipaddr = case self.network[:ip_assignment]
               when "asc"
                 first = addr || start_range
                 boundaries = leased_ips(first, end_range).leased_ip_bound_lease.limit(2).all
                 ip = check_ascending_order(boundaries, first)
                 if ip.nil?
                   last = addr || end_range
                   boundaries = leased_ips(start_range, last).leased_ip_bound_lease.limit(2).all
                   ip = check_ascending_order(boundaries, start_range)
                 end
                 ip
               when "desc"
               else
               end
    end

    def check_ascending_order(boundaries, addr)
      return addr if boundaries.size == 0

      boundary = boundaries.first
      return addr if boundary[:prev].nil? && boundary[:ipv4] != addr

      ipaddr = nil
      boundaries.each do |b|
          next unless b[:follow].nil?
          
          ipaddr = b[:ipv4]+1 if b[:ipv4]+1 <= end_range
          break unless ipaddr.nil?
      end

      ipaddr
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
