# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Setup vnics by following params#vifs template without leasing ip address yet.
      class SpecifyNetwork < NetworkScheduler
        include Dcmgr::Logger

        configuration do
          param :template, :default=>{}
        end

        # Placeholder code. Identical to vifsrequestparam with attach_to_network removed and mac_addr added
        # We can remove this class when we get rid of the instance#add_nic method
        def schedule(instance)
          index = 0

          Dcmgr::Scheduler::Network.check_vifs_parameter_format(instance.request_params["vifs"])

          instance.request_params['vifs'].each { |name, param|
            vnic_params = {
              :index => param['index'] ? param['index'].to_i : index,
              :bandwidth => 100000,
              :security_groups => param['security_groups'],
              :mac_addr => param['mac_addr']
            }

            index = [index, vnic_params[:index]].max + 1
            vnic = instance.add_nic(vnic_params)

            next if param['network'].to_s.empty?

            network = Models::Network[param['network'].to_s]
            raise NetworkSchedulingError, "Network '#{param['network'].to_s}' doesn't exist." if network.nil?

            vnic.nat_network = Models::Network[param['nat_network'].to_s] unless param['nat_network'].nil?

            vnic.network = network
            vnic.save
            # vnic.attach_to_network(network)
          }
        end

      end
    end
  end
end
