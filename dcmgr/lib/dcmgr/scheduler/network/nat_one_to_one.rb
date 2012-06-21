# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # One internal address + NAT external address to single interface.
      class NatOneToOne < NetworkScheduler
        configuration do
          param :network_id
          param :nat_network_id

          def validate(errors)
            errors << "Missing network_id parameter" if @config[:network_id].nil?
            errors << "Missing nat_network_id parameter" if @config[:nat_network_id].nil?
          end
        end

        def schedule(instance)
          network = Models::Network[options.network_id]
          nat_network = Models::Network[options.nat_network_id]

          return unless instance.request_params[:vifs].is_a?(Hash)
          vif_template = instance.request_params[:vifs].find{ |name,v| v[:index] == 0 }.last

          vnic = instance.add_nic(vif_template)
          vnic.nat_network = nat_network
          vnic.attach_to_network(network)
        end
      end
    end
  end
end
