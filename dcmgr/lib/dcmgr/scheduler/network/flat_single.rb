# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Simple network scheduler
      # assign IP address from first found network to single interface.
      class FlatSingle < NetworkScheduler
        
        def schedule(instance)
          # add single interface and set network
          network = Models::Network.first
          vif_template = instance.spec.vifs[instance.spec.vifs.keys.first] ||
            {:index=>0, :bandwidth=>100000}
          
          vnic = instance.add_nic(vif_template)
          vnic.network = network
          vnic.save
        end
      end
    end
  end
end
