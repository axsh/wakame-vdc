# -*- coding: utf-8 -*-

require 'json'

module Dcmgr
  module Scheduler
    module Network
      # Setup vnics by following params#vifs template.
      class VifParamTemplate < NetworkScheduler
        include Dcmgr::Logger

        configuration do
          param :template, :default=>{}
        end

        def schedule(instance)
          index = 0

          return unless instance.request_params['vifs'].is_a?(Hash)

          instance.request_params['vifs'].each { |name, param|
            vnic_params = {
              :index => param['index'] ? param['index'].to_i : index,
              :bandwidth => 100000,
              :security_groups => param['security_groups'],
            }

            index = [index, vnic_params[:index]].max + 1
            vnic = instance.add_nic(vnic_params)

            next if param['network'].nil? || param['network'].to_s == ""
            network = Models::Network[param['network'].to_s]
            next if network.nil?

            vnic.attach_to_network(network)
          }
        end
      end
    end
  end
end
