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
          param :algorithm

          DSL do
            def pair(key,value)
              @config[:pairs] ||= {}
              @config[:pairs][key] = value
            end
          end

          on_initialize_hook do
            def validate(errors)
               @config[:algorithm] = :least_allocation if @config[:algorithm].nil?
               unless NetworkGroup::ALGORITHMS.member? @config[:algorithm]
                 errors << "Unknown algorithm: #{@config[:algorithm]}"
               end
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
            logger.info "Chose network group: '#{tag_id}'."

            # Create the vnic
            vnic = Dcmgr::Models::NetworkVif.new({"account_id" => instance.account_id, "device_index" => vif_template["index"]})

            # Choose a network from the network group
            selected_network = NetworkGroup::Algorithm.__send__(options.algorithm, network_group.mapped_resources)

            vnic.save
            instance.add_network_vif(vnic)
            vnic.network = selected_network
            logger.info "Successfully attached vnic '#{vnic.canonical_uuid}' to network '#{selected_network.canonical_uuid}'."

            # Set security groups
            vnic.add_security_groups_by_id(vif_template["security_groups"] || [])
          }
        end
      end
    end
  end
end
