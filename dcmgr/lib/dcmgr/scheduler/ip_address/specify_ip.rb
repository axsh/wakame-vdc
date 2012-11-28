# -*- coding: utf-8 -*-

require "ipaddress"

module Dcmgr::Scheduler::IPAddress

  class SpecifyIP < Dcmgr::Scheduler::IPAddressScheduler
    configuration do
    end

    M = Dcmgr::Models
    S = Dcmgr::Scheduler

    def schedule(network_vif)
      template = network_vif.instance.request_params["vifs"].values.find { |temp| temp["index"] = network_vif.device_index }
      raise S::IPAddressSchedulerError, "No entry found in the vifs parameter for index #{network_vif.device_index}" if template.nil?
      raise S::IPAddressSchedulerError, "No network assigned to this vnic yet" if network_vif.network.nil?

      ip_addr = perform_checks(network_vif.network,template["ipv4_addr"])
      assign_ip(network_vif,network_vif.network,ip_addr)

      if template["nat_ipv4_addr"] && network_vif.nat_network
        nat_addr = perform_checks(network_vif.nat_network,template["nat_ipv4_addr"])
        assign_ip(network_vif,network_vif.nat_network,nat_addr)
      end
    end

    private
    def assign_ip(vif,network,ip)
      M::NetworkVifIpLease.create(:ipv4=>ip.to_i, :network_id=>network.id, :network_vif_id=>vif.id, :description=>ip.to_s)
    end

    def perform_checks(nw,ip)
      raise S::IPAddressSchedulerError, "Invalid ipv4 address: #{ip}." unless IPAddress.valid_ipv4?(ip)
      leaseaddr = IPAddress::IPv4.new(ip)
      raise S::IPAddressSchedulerError, "Address #{ip} not in segment #{nw.ipv4_network}/#{nw.prefix}" unless IPAddress("#{nw.ipv4_network}/#{nw.prefix}").include?(leaseaddr)
      #TODO: Perform a working check here
      # raise S::IPAddressSchedulerError, "Address #{ip} not in dhcp ranges" unless nw.include?(ip)
      raise S::IPAddressSchedulerError, "IP Address is already leased: #{leaseaddr.to_s}" unless M::IpLease.filter(:ipv4 => leaseaddr.to_i).empty?

      leaseaddr
    end
 end
end
