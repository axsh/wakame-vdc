# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network

      # This scheduler chooses a network group based on one of the request parameters.
      # It will then sort networks in the group based on their sort indices and lease an IP
      # from the first network that still has dynamic range available.
      #
      #
      # Usage (in dcmgr.conf):
      #  network_scheduler(:RequestParamToGroup) {
      #     key 'instance_spec_name'
      #
      #     pair 'vz.small',  'nwg-small'
      #     pair 'vz.large',  'nwg-large'
      #     pair 'kvm.small', 'nwg-kvm'
      #     pair 'kvm.large', 'nwg-kvm'
      #
      #     default 'nwg-shnet'
      #  }
      class RequestParamToGroup < NetworkScheduler
        include Dcmgr::Logger

        configuration do
          param :key
          param :default

          DSL do
            def pair(key,value)
              @config[:pairs] ||= {}
              @config[:pairs][key] = value
            end
          end
        end

        def schedule(instance)
          Dcmgr::Scheduler::Network.check_vifs_parameter_format(instance.request_params["vifs"])

          instance.request_params["vifs"].each { |name, vif_template|
            request_param = instance.request_params[options.key]

            # Get the network group
            tag_id = options.pairs[request_param] || options.default rescue options.default
            raise Dcmgr::Scheduler::NetworkShedulingError, "No default network group set" if tag_id.nil?

            network_group = Dcmgr::Tags::NetworkGroup[tag_id]
            raise Dcmgr::Scheduler::NetworkSchedulingError, "Unknown network group: #{tag_id}" if network_group.nil?
            logger.debug "Chose network group: '#{tag_id}'."

            # Create the vnic
            vnic = instance.add_nic(vif_template)

            # Attach to the first network that has available ip leases left
            networks = network_group.sorted_mapped_uuids.map {|mapped| Dcmgr::Models::Network[mapped.uuid]}
            begin
              network = networks.shift
              raise Dcmgr::Scheduler::NetworkSchedulingError, "No available ip addresses left in network group '#{tag_id}'." if network.nil?
              logger.debug "Trying to attach vnic '#{vnic.canonical_uuid}' to network '#{network.canonical_uuid}'."

              vnic.attach_to_network(network)
            rescue Dcmgr::Models::OutOfIpRange => e
              logger.debug "No more dynamic ip addresses available in network '#{network.canonical_uuid}'"
              retry
            end

            logger.debug "Successfully attached vnic '#{vnic.canonical_uuid}' to network '#{network.canonical_uuid}'."
          }
        end
      end
    end
  end
end
