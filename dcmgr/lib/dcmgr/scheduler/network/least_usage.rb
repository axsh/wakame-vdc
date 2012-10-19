# -*- coding: utf-8 -*-
module Dcmgr
  module Scheduler
    module Network
      class LeastUsage < NetworkScheduler

        include Dcmgr::Logger

        configuration do
          param :network_group_id
        end

        def schedule(instance)
          logger.info "Scheduling network for the instance #{instance.canonical_uuid}"

          tag_id = options.network_group_id
          raise Dcmgr::Scheduler::NetworkSchedulingError, "No default network group set" if tag_id.nil?

          network_group = Dcmgr::Tags::NetworkGroup[tag_id]
          raise Dcmgr::Scheduler::NetworkSchedulingError, "Unknown network group: #{tag_id}" if network_group.nil?
          logger.info "Select network group: '#{tag_id}'."

          networks = network_group.sorted_mapped_uuids.map {|mapped| Dcmgr::Models::Network[mapped.uuid]}

          network_candidates = {}
          networks.each {|n|
            network_candidates.store(n.canonical_uuid, n.allocated_ip_nums)
          }

          begin
            raise "No available network left in network group" if network_candidates.empty?
            logger.info "Candidate networks #{network_candidates}"

            # Select the network with the least number of allocated IP.
            selected_network = network_candidates.min_by {|uuid, ip_nums| ip_nums}
            network_uuid = selected_network[0]
            logger.info "Select network #{network_uuid}"

            # Create the vnic
            vif_template = instance.request_params[:vifs] || {:index=>0}
            vnic = instance.add_nic(vif_template)

            network = Dcmgr::Models::Network[network_uuid]
            raise Dcmgr::Scheduler::NetworkSchedulingError, "No available ip addresses left in network group '#{tag_id}'." if network.nil?
            logger.info "Trying to attach vnic '#{vnic.canonical_uuid}' to network '#{network.canonical_uuid}'."

            vnic.attach_to_network(network)
            logger.info "Successfully attached vnic '#{vnic.canonical_uuid}' to network '#{network.canonical_uuid}'."
          rescue Dcmgr::Models::OutOfIpRange => e
            logger.error "No more dynamic ip addresses available in network '#{network.canonical_uuid}'"
            network_candidates.delete(network_uuid)
            retry
          end

        end
      end
    end
  end
end
