# -*- coding: utf-8 -*-
module Dcmgr
  module Scheduler
    module Network
      class NetworkGroup < NetworkScheduler

        include Dcmgr::Logger

        ALGORITHMS = [
          :least_allocation
        ].freeze

        configuration do
          param :network_group_id
          param :algorithm

          on_initialize_hook do
            def validate(errors)
               @config[:algorithm] = :least_allocation if @config[:algorithm].nil?
               unless ALGORITHMS.member? @config[:algorithm]
                 errors << "Unknown algorithm: #{@config[:algorithm]}"
               end
            end
          end
        end

        def schedule(instance)
          logger.info "Scheduling network for the instance #{instance.canonical_uuid}"

          # Create the vnics
          vif_templates = instance.request_params["vifs"] || { "eth0" => {"index"=>"0","security_groups" => []} }
          vif_templates.each { |vif_name,vif_temp|
            tag_id = vif_temp["network"] || options.network_group_id
            raise Dcmgr::Scheduler::NetworkSchedulingError, "No default network group set" if tag_id.nil?

            network_group = Dcmgr::Tags::NetworkGroup[tag_id]
            raise Dcmgr::Scheduler::NetworkSchedulingError, "Unknown network group: #{tag_id}" if network_group.nil?
            logger.info "Selected network group: '#{tag_id}'."

            networks = network_group.mapped_resources

            network_candidates = {}
            networks.each {|n|
              network_candidates.store(n.canonical_uuid, n.allocated_ip_nums)
            }

            begin
              raise "No available network left in network group" if network_candidates.empty?
              logger.info "Candidate networks #{network_candidates}"


              # Select the network with the least number of allocated IP.
              selected_network = Algorithm.__send__(options.algorithm, network_candidates)
              network_uuid = selected_network[0]
              logger.info "Selected network #{network_uuid}"

              vnic = instance.add_nic(vif_temp)

              network = Dcmgr::Models::Network[network_uuid]
              raise Dcmgr::Scheduler::NetworkSchedulingError, "No available ip addresses left in network group '#{tag_id}'." if network.nil?
              logger.info "Trying to attach vnic '#{vnic.canonical_uuid}' to network '#{network.canonical_uuid}'."

              vnic.attach_to_network(network)
              logger.info "Successfully attached vnic '#{vnic.canonical_uuid}' to network '#{network.canonical_uuid}'."
            rescue Dcmgr::Models::OutOfIpRange => e
              logger.warning "No more dynamic ip addresses available in network '#{network.canonical_uuid}'"
              network_candidates.delete(network_uuid)
              retry
            end
          }

        end

        class Algorithm
          def self.least_allocation(networks)
            networks.min_by {|uuid, ip_nums| ip_nums}
          end
        end
      end
    end
  end
end
