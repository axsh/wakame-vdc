# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::IPAddress

  class Incremental < Dcmgr::Scheduler::IPAddressScheduler
    configuration do
    end

    include Dcmgr::Models

    def schedule(options)
      if options.is_a?(NetworkVif)
        options = {
          :network_vif => options,
          :network => options.network,
        }
      end

      raise ArgumentError unless options.is_a?(Hash)
      raise ArgumentError unless options[:network].is_a?(Network)
      raise ArgumentError unless options[:network_vif].nil? || options[:network_vif].is_a?(NetworkVif)
      raise ArgumentError unless options[:ip_pool].nil? || options[:ip_pool].is_a?(IpPool)
      raise ArgumentError unless options[:ip_pool] || options[:network_vif]

      # find latest ip
      network = options[:network]
      ip_lease_alives = network.network_vif_ip_lease_dataset.alives

      latest_ip = ip_lease_alives.filter(:alloc_type =>NetworkVifIpLease::TYPE_AUTO).order(:updated_at.desc).first
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

      fields = {
        :ipv4 => leaseaddr.to_i,
        :network_id => network.id,
        :description => leaseaddr.to_s
      }
      fields[:network_vif_id] = options[:network_vif].id if options[:network_vif]

      if options[:ip_pool]
        ip_handle = IpHandle.create({:display_name => ""}) || raise("Could not create IpHandle.")
        fields[:ip_handle_id] = ip_handle.id
      end

      NetworkVifIpLease.create(fields)
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
          is_loop = false

          leaseaddr = i.available_ip(f, t, order)
          break if leaseaddr.nil?
          check_ip = IPAddress::IPv4.parse_u32(leaseaddr, network[:prefix])
          # To check the IP address that can not be used.
          # TODO No longer needed in the future.
          if network.reserved_ip?(check_ip)
            network.network_vif_ip_lease_dataset.add_reserved(check_ip.to_s)
            is_loop = true
          end
          case order
          when :asc
            f = check_ip.to_i
          when :desc
            t = check_ip.to_i
          else
            raise "Unsupported IP address assignment: #{order.to_s}"
          end
        end while is_loop
        break unless leaseaddr.nil?
      }
      leaseaddr
    end
  end
end
