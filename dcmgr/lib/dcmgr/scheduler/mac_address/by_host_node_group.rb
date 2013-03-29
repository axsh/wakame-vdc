# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module MacAddress
      # Placeholder mac range scheduler
      # Pair a mac address range to a host node group
      class ByHostNodeGroup < MacAddressScheduler
        configuration do
          param :default

          DSL do
            def pair(hng,mr)
              @config[:pairs] ||= {}
              @config[:pairs][hng] = mr
            end
          end
        end

        M = Dcmgr::Models

        def schedule(network_vif)
          host_node = network_vif.instance.host_node
          raise "Unable to determine host node group because host node is not set yet" if host_node.nil?
          host_group_ids = host_node.groups.map { |g| g.canonical_uuid }
          mac = nil

          host_group_ids.each { |hid|
            next unless options.pairs.keys.member?(hid)
            range = M::MacRange[options.pairs[hid]]
            next if range.nil? || (not range.available_macs_left?)

            mac = range.get_random_available_mac
            raise MacAddressSchedulerError, "No available MAC addresses left in range '#{range.canonical_uuid}'" if mac.nil?
          }

          if mac.nil?
            range = M::MacRange[options.default]
            raise MacAddressSchedulerError, "MAC address range '#{options.default}' not found" if range.nil?

            mac = range.get_random_available_mac
            raise MacAddressSchedulerError, "No available MAC addresses left in default range '#{range.canonical_uuid}'" if mac.nil?
          end

          M::MacLease.lease(mac.to_s(16))
          network_vif.mac_addr = mac.to_s(16)
        end

      end
    end
  end
end
