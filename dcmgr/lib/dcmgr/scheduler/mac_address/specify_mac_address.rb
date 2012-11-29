# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::MacAddress

  class SpecifyMacAddress < Dcmgr::Scheduler::MacAddressScheduler
    configuration do
    end

    M = Dcmgr::Models
    S = Dcmgr::Scheduler

    def schedule(network_vif)
      template = network_vif.instance.request_params["vifs"].values.find { |temp| temp["index"] = network_vif.device_index }
      raise S::MacAddressSchedulerError, "No entry found in the vifs parameter for index #{network_vif.device_index}" if template.nil?

      addr_str = template["mac_addr"]
      addr_len = addr_str.length
      raise S::MacAddressSchedulerError, "Invalid mac address: #{mac_addr}" unless (addr_len == 6 || addr_len == 12) && addr_str =~ /^[0-9a-fA-F]{1,#{addr_len}}$/

      vendor_id, addr = M::MacLease.string_to_ints(addr_str)
      # Because some db tables split the mac address and others don't.
      full_addr = (vendor_id * 0x1000000) + addr
      full_addr_str = full_addr.to_s(16)

      # Check if this address is available
      raise S::MacAddressSchedulerError, "Mac address #{addr_str} is already leased." unless M::MacLease.filter(:mac_addr => full_addr).empty?

      # Check if this mac address exists in any of the ranges
      raise S::MacAddressSchedulerError, "There is no mac address range defined that includes #{full_addr.to_s(16)}" unless M::MacRange.exists_in_any_range?(vendor_id,addr)

      M::MacLease.lease(full_addr_str)
      network_vif.mac_addr = full_addr_str
    end

  end
end
