# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew

    many_to_one :network

    def_dataset_method(:leased_ip_bound_lease) { |network_id, from, to|
      filter_join_main = {:ip_leases__ipv4=>from..to} & {:ip_leases__network_id=>network_id}
      filter_join_prev = {:prev__ipv4=>from..to} & {:prev__network_id=>network_id} & {:ip_leases__ipv4=>:prev__ipv4 + 1}
      filter_join_follow = {:follow__ipv4=>from..to} & {:follow__network_id=>network_id} & {:ip_leases__ipv4=>:follow__ipv4 - 1}

      select_statement = IpLease.select(:ip_leases__ipv4, :prev__ipv4___prev, :follow__ipv4___follow).filter(filter_join_main)
      select_statement = select_statement.join_table(:left, :ip_leases___prev, filter_join_prev)
      select_statement = select_statement.join_table(:left, :ip_leases___follow, filter_join_follow)
      select_statement.filter({:prev__ipv4=>nil} | {:follow__ipv4=>nil})
    }

    def validate
      # validate ipv4 syntax
      begin
        addr = IPAddress::IPv4::parse_u32(self.ipv4)
        # validate if ipv4 is in the range of network_id.
        unless network.include?(addr)
          errors.add(:ipv4, "IP address #{addr} is out of range: #{network.canonical_uuid})")
        end
        # Set IP address string canonicalized by IPAddress class.
        self.ipv4 = addr.to_i
      rescue => e
        errors.add(:ipv4, "Invalid IP address syntax: #{self.ipv4} (#{e})")
      end
    end

    def self.lease(network_vif, network)
      raise ArgumentError unless network_vif.is_a?(NetworkVif)
      raise ArgumentError unless network.is_a?(Network)

      # find latest ip
      latest_ip = network.network_vif_ip_lease_dataset.alives.filter(:alloc_type =>NetworkVifIpLease::TYPE_AUTO).order(:updated_at.desc).first
      ipaddr = latest_ip.nil? ? nil : latest_ip.ipv4_i
      leaseaddr = case network[:ip_assignment]
                  when "asc"
                    ip = get_lease_address(network, ipaddr, nil, :asc)
                    ip = get_lease_address(network, nil, ipaddr, :asc) if ip.nil?
                    ip
                  when "desc"
                    ip = get_lease_address(network, nil, ipaddr, :desc)
                    ip = get_lease_address(network, ipaddr, nil, :desc) if ip.nil?
                    ip
                  else
                    raise "Unsupported IP address assignment: #{network[:ip_assignment]}"
                  end
      raise OutOfIpRange, "Run out of dynamic IP addresses from the network segment: #{network.ipv4_network.to_s}/#{network.prefix}" if leaseaddr.nil?

      leaseaddr = IPAddress::IPv4.parse_u32(leaseaddr)
      NetworkVifIpLease.create(:ipv4=>leaseaddr.to_i, :network_id=>network.id, :network_vif_id=>network_vif.id, :description=>leaseaddr.to_s)
    end

    private
    def self.get_lease_address(network, from_ipaddr, to_ipaddr, order)
      from_ipaddr = 0 if from_ipaddr.nil?
      to_ipaddr = 0xFFFFFFFF if to_ipaddr.nil?
      raise ArgumentError unless from_ipaddr.is_a?(Fixnum)
      raise ArgumentError unless to_ipaddr.is_a?(Fixnum)

      leaseaddr = nil

      range_order = {
        :asc => :range_begin.asc,
        :desc => :range_end.desc,
      }[order]

      network.dhcp_range_dataset.containing_range(from_ipaddr, to_ipaddr).order(range_order).all.each {|i|
        start_range = i.range_begin.to_i
        end_range = i.range_end.to_i

        raise "Got from_ipaddr > end_range: #{from_ipaddr} > #{end_range}" if from_ipaddr > end_range
        f = (from_ipaddr > start_range) ? from_ipaddr : start_range
        raise "Got to_ipaddr < start_range: #{to_ipaddr} < #{start_range}" if to_ipaddr < start_range
        t = (to_ipaddr < end_range) ? to_ipaddr : end_range

        begin
          leaseaddr = i.available_ip(f, t, order)
          break if leaseaddr.nil?
          check_ip = IPAddress::IPv4.parse_u32(leaseaddr, network[:prefix])
          # To check the IP address that can not be used.
          # TODO No longer needed in the future.
          if network.reserved_ip?(check_ip)
            network.network_vif_ip_lease_dataset.add_reserved(check_ip.to_s)
          end
          case order
          when :asc
            f = check_ip.to_i
          when :desc
            t = check_ip.to_i
          else
            raise "Unsupported IP address assignment: #{order.to_s}"
          end
        end while self.find({:network_id => network.id, :ipv4 => leaseaddr})
        break unless leaseaddr.nil?
      }
      leaseaddr
    end
  end
end
