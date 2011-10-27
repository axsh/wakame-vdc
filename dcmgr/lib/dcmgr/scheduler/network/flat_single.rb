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
        end
      end
    end
  end
end
