# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Setup vnics by following InstanceSpec#vifs template.
      class VifTemplate < NetworkScheduler
        configuration do
          param :template, :default=>{}
        end
        
        def schedule(instance)
          instance.spec.vifs.each { |name, vif|
            vnic = instance.add_nic(vif)
            next if options.template[name].nil?

            network = Models::Network[options.template[name]]
            next if network.nil?

            vnic.attach_to_network(network)
          }
        end
      end
    end
  end
end
