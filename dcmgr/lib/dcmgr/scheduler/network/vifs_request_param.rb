# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Setup vnics by following params#vifs template.
      class VifsRequestParam < NetworkScheduler
        include Dcmgr::Logger

        configuration do
          param :template, :default=>{}
        end

        def schedule(instance)
          Dcmgr::Scheduler::Network.check_vifs_parameter_format(instance.request_params["vifs"])

          instance.request_params['vifs'].each { |name, param|
            if param['network'].to_s.empty?
              logger.warn "No network specified for vif #{name} on instance #{instance.canonical_uuid}. Not scheduling this vif."
              next
            end
            logger.info "Scheduling vnic #{name} in network #{param["network"]} for instance #{instance.canonical_uuid}"

            #TODO: Check for index
            vnic = Dcmgr::Models::NetworkVif.new({"account_id" => instance.account_id, "device_index" => param["index"]})

            # Schedule mac address for the vnic
            mac_sched = if param["mac_addr"]
              Dcmgr::Scheduler::MacAddress::SpecifyMacAddress.new
            else
              Dcmgr::Scheduler.service_type(instance).mac_address
            end
            mac_sched.schedule(vnic)
            vnic.save
            instance.add_network_vif(vnic)

            network = Models::Network[param['network']]
            raise NetworkSchedulingError, "Network '#{param['network']}' doesn't exist." if network.nil?

            unless param['nat_network'].nil?
              nat_network = Models::Network[param['nat_network']]
              raise NetworkSchedulingError, "Network '#{param['nat_network']}' doesn't exist." if nat_network.nil?
              vnic.nat_network = nat_network
            end

            vnic.add_security_groups_by_id(param["security_groups"] || [])

            vnic.network = network
          }
        end
      end

    end
  end
end
