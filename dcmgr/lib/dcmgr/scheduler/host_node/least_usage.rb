# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      # Find host node which has the largest available capacity.
      class LeastUsage < HostNodeScheduler
        include Dcmgr::Logger
        include AllowOverCommit
        
        configuration do
          SORT_PRIORITY_KEYS=[:cpu, :memory].freeze

          param :sort_priority, :default=>:memory

          def validate(errors)
            unless SORT_PRIORITY_KEYS.member?(@config[:sort_priority])
              errors << "Unknown sort priority: #{@config[:sort_priority]}"
            end
          end
        end

        def schedule(instance)
          host_node = host_nodes_in_priority_order(instance).find_all { |hn|
            hn.available_cpu_cores >= instance.cpu_cores && \
            hn.available_memory_size >= instance.memory_size
          }.first

          if host_node.nil?
            raise HostNodeSchedulingError, "Unable to find a suitable host node for #{instance.image.arch} #{instance.hypervisor}."
          end
          instance.host_node = host_node

          logger.info("Scheduling host node #{instance.host_node.node_id} for the instance #{instance.canonical_uuid}")
        end

        def schedule_over_commit(instance)
          host_node = host_nodes_in_priority_order(instance).first

          if host_node.nil?
            raise HostNodeSchedulingError, "Unable to find a suitable host node for #{instance.image.arch} #{instance.hypervisor}."
          end
          instance.host_node = host_node

          logger.info("Scheduling host node #{instance.host_node.node_id} for the instance #{instance.canonical_uuid}")
        end

        private
        def host_nodes_in_priority_order(instance)
          ds = Models::HostNode.online_nodes.filter(:arch=>instance.image.arch,
                                                    :hypervisor=>instance.hypervisor)
          host_nodes_ary = ds.all.sort_by { |hn|
            case options.sort_priority
            when :cpu
              hn.available_cpu_cores
            when :memory
              hn.available_memory_size
            end
          }.reverse

          if host_nodes_ary.empty?
            raise HostNodeSchedulingError, "Unable to find a suitable host node for #{instance.image.arch} #{instance.hypervisor}."
          end

          host_nodes_ary
        end
      end
    end
  end
end
