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
          vif_template = if instance.request_params["vifs"]
            instance.request_params["vifs"].values.first
          else
            {:index=>0, "security_groups"=>[]}
          end

          vnic = instance.add_nic(vif_template)
          vnic.attach_to_network(network)
        end
      end
    end
  end
end
