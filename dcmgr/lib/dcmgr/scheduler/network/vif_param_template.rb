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

          instance.request_params[:vifs].each { |name, param|
            # Remove index?
            vnic = instance.add_nic({ :index => index,
                                      :bandwidth => 100000})
            index += 1

            next if param['network'].nil?
            network = Models::Network[param['network']]
            next if network.nil?

            vnic.attach_to_network(network)
          }
        end
      end
    end
  end
end
