# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::MacAddress
  # Minimal default mac address range scheduler
  class Default < Dcmgr::Scheduler::MacAddressScheduler
    configuration do
    end

    M = Dcmgr::Models
    S = Dcmgr::Scheduler

    def schedule(network_vif)
      range = M::MacRange.first
      raise S::MacAddressSchedulerError, "No mac address ranges found in the database." if range.nil?

      mac = range.get_random_available_mac
      raise S::MacAddressSchedulerError, "No available MAC addresses left in default range '#{range.canonical_uuid}'" if mac.nil?

      M::MacLease.lease(mac.to_s(16))
      network_vif.mac_addr = mac.to_s(16)
    end

  end
end
