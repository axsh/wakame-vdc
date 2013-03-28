# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # Dynamic IP address range in the network.
  class DhcpRange < BaseNew

    many_to_one :network

    def_dataset_method(:containing_range) { |begin_range,end_range|
      new_dataset = self
      new_dataset = new_dataset.filter("range_end >= ?", begin_range) if begin_range
      new_dataset = new_dataset.filter("range_begin <= ?", end_range) if end_range
      new_dataset
    }

    def validate
      super

      validate_address(:range_begin, self.range_begin)
      validate_address(:range_end, self.range_end)

      if self.range_begin > self.range_end
        errors.add(:range_begin, "Range begin (#{self.range_begin}) must be smaller than range end (#{self.range_end})")
      end
    end

    def before_save
      self[:description] = "begin:#{self.range_begin}/end:#{self.range_end}"
    end

    def range_begin
      IPAddress::IPv4.parse_u32(super, network.prefix)
    end

    def range_end
      IPAddress::IPv4.parse_u32(super, network.prefix)
    end

    def leased_ips(from, to)
      IpLease.where(:ip_leases__network_id=>self.network_id).filter(:ip_leases__ipv4=>from..to)
    end

    def available_ip(from, to, order)
      ipaddr = case order
               when :asc
                 boundaries = IpLease.leased_ip_bound_lease(self.network_id, from, to).limit(2).all
                 ip = get_assignment_ip(boundaries, from, to)
               when :desc
                 boundaries = IpLease.leased_ip_bound_lease(self.network_id, from, to).order(:ip_leases__ipv4.desc).limit(2).all
                 ip = get_assignment_ip(boundaries, to, from)
               else
                 raise "Unsupported IP address assignment: #{network[:ip_assignment]}"
               end
    end

    def get_assignment_ip(boundaries, from, to)
      if from <= to
        prev = :prev
        follow = :follow
        inequality_sign = :<
        number = :+
      else
        prev = :follow
        follow = :prev
        inequality_sign = :>
        number = :-
      end
      return from if boundaries.size == 0
      return from if boundaries[0][prev].nil? && boundaries[0][:ipv4] != from

      start_range = nil

      if boundaries[0][follow].nil?
        start_range = boundaries[0][:ipv4] if boundaries[0][:ipv4] != to
      elsif boundaries.size == 2 && boundaries[1][follow].nil?
        start_range = boundaries[1][:ipv4] if boundaries[1][:ipv4] != to
      end

      return start_range ? start_range.method(number).call(1) : nil
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
      ary.first.unshift(range_begin.to_i)
      ary.last.push(range_end.to_i)

      ary
    end

    private
    def validate_address(column_name,ipv4_address)
      if !self.network.ipv4_ipaddress.include?(ipv4_address)
        errors.add(column_name, "Out of subnet range: #{ipv4_address}")
      end

      if self.network.ipv4_ipaddress.network == ipv4_address
        errors.add(column_name, "Network address can't be added to dhcp range: #{ipv4_address}")
      end

      if self.network.ipv4_ipaddress.broadcast == ipv4_address
        errors.add(column_name, "Broadcast address can't be added to dhcp range: #{ipv4_address}")
      end
    end

  end
end
