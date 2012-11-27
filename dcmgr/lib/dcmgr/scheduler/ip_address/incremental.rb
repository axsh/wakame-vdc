# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::IPAddress

  class Incremental < Dcmgr::Scheduler::IPAddressScheduler
    configuration do
    end

    include Dcmgr::Models

    def schedule(network_vif)
      network = network_vif.network
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
    def get_lease_address(network, from_ipaddr, to_ipaddr, order)
      from_ipaddr = 0 if from_ipaddr.nil?
      to_ipaddr = 0xFFFFFFFF if to_ipaddr.nil?
      raise ArgumentError unless from_ipaddr.is_a?(Integer)
      raise ArgumentError unless to_ipaddr.is_a?(Integer)

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
        end while IpLease.find({:network_id => network.id, :ipv4 => leaseaddr})
        break unless leaseaddr.nil?
      }
      leaseaddr
    end
  end
end
