# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Simple network scheduler
      # Add a vnic and assign an IP address
      class FlatSingle < NetworkScheduler
        
        def schedule(instance)
          # add single interface and set network
          network = Models::Network.first
          
          vnic = instance.add_nic(network)
          Models::IpLease.lease(vnic, network)
          
          #Lease the nat ip in case there is an outside network mapped
          #nat_network = Network.find(:id => vnic[:nat_network_id])
          #Models::IpLease.lease(vnic,nat_network) unless nat_network.nil? 
        end
      end
    end
  end
end
