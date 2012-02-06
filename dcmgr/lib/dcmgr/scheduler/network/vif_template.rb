# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Setup vnics by following InstanceSpec#vifs template.
      class VifTemplate < NetworkScheduler
        
        def schedule(instance)
          instance.spec.vifs.each { |name, vif|
            vnic = instance.add_nic(vif)
            vnic.attach_to_network(Models::Network[@options[name]])
          }
        end
      end
    end
  end
end
