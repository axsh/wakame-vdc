# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # One internal address + NAT external address to single interface.
      class NatOneToOne < NetworkScheduler
        
        def schedule(instance)
          network = Models::Network[@options.network_id]
          nat_network = Models::Network[@options.nat_network_id]

          vif_template = instance.spec.vifs.find{ |name,v| v[:index] == 0 }
          vnic = instance.add_nic(vif_template)
          vnic.network = network
          vnic.nat_network = nat_network
          vnic.save
        end
      end
    end
  end
end
