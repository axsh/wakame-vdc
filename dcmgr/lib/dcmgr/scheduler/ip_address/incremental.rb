# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::IPAddress

  class Incremental < Dcmgr::Scheduler::IPAddressScheduler
    configuration do
    end

    include Dcmgr::Logger
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
                    ip = get_lease_address(network, ipaddr, nil, :asc, network_vif)
                    ip = get_lease_address(network, nil, ipaddr, :asc, network_vif) if ip.nil?
                    ip
                  when "desc"
                    ip = get_lease_address(network, nil, ipaddr, :desc, network_vif)
                    ip = get_lease_address(network, ipaddr, nil, :desc, network_vif) if ip.nil?
                    ip
                  else
                    raise "Unsupported IP address assignment: #{network[:ip_assignment]}"
                  end
      raise OutOfIpRange, "Run out of dynamic IP addresses from the network segment: #{network.ipv4_network.to_s}/#{network.prefix}" if leaseaddr.nil?

      leaseaddr = IPAddress::IPv4.parse_u32(leaseaddr)
      NetworkVifIpLease.create(:ipv4=>leaseaddr.to_i, :network_id=>network.id, :network_vif_id=>network_vif.id, :description=>leaseaddr.to_s)
    end

    private
    def get_lease_address(network, from_ipaddr, to_ipaddr, order,network_vif)
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
          is_retention = false

          leaseaddr = i.available_ip(f, t, order)
          break if leaseaddr.nil?
          check_ip = IPAddress::IPv4.parse_u32(leaseaddr, network[:prefix])
          # To check the IP address that can not be used.
          # TODO No longer needed in the future.
          if network.reserved_ip?(check_ip)
            network.network_vif_ip_lease_dataset.add_reserved(check_ip.to_s)
            is_loop = true
          else
            vif_lease = NetworkVifIpLease.filter(:ipv4 => check_ip.to_i, :deleted_at => !nil).order_by(:deleted_at).last
            unless vif_lease.nil?
              logger.debug "#{check_ip} has been leased before"
              release_time = Time.at(vif_lease.deleted_at.to_i + vif_lease.network.retention_seconds)

              # If this ip's retention period has passed, we can use it
              retention_passed = Time.now > release_time
              logger.debug "Has #{check_ip}'s retention period passed? #{retention_passed}"

              # If this ip address belonged to us last time it was leased, we can ignore the retention period
              was_ours = vif_lease.network_vif.account_id == network_vif.account_id
              logger.debug "Was this ip ours last time? #{was_ours}"
              is_retention = is_loop = !(retention_passed || was_ours)
            end
          end

          case order
          when :asc
            f = check_ip.to_i
            f += 1 if is_retention
          when :desc
            t = check_ip.to_i
            t -= 1 if is_retention
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
