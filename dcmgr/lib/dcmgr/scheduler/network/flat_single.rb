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
          vif_template = instance.request_params[:vifs] || {:index=>0}

          vnic = instance.add_nic(vif_template)
          vnic.attach_to_network(network)
        end
      end
    end
  end
end
