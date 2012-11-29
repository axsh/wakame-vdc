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
      Dcmgr::Scheduler.service_type(network_vif.instance).ip_address.schedule(network_vif)
    end

  end
end
