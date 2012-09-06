# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Meta scheduler calls another scheduler specified by user.
      class PerInstance < NetworkScheduler
        include Dcmgr::Logger

        configuration do
          DSL do
            def default(sched_class_name, &blk)
              add(:default, sched_class_name, &blk)
            end

            def add(name, sched_class_name, &blk)
              @config[:schedulers] ||= {}              
              c = ::Dcmgr::Scheduler::Network.scheduler_class(sched_class_name)

              unless c < ::Dcmgr::Scheduler::NetworkScheduler
                raise "Invalid scheduler class is set: #{c.to_s}"
              end
              @config[:schedulers][name.to_sym] = ::Dcmgr::Configurations::Dcmgr::Scheduler::DSL.load_section(c,
                                                                                                              ::Dcmgr::Configurations::Dcmgr::NetworkScheduler,
                                                                                                              ::Dcmgr::Scheduler::Network,
                                                                                                              &blk)
              self
            end
          end
        end

        def schedule(instance)
          sched_name = instance.request_params['network_scheduler']
          if sched_name.nil? || sched_name == ''
            if options.schedulers[:default]
              sched_conf = options.schedulers[:default]
            else
              raise "Unable to find any network schedulers"
            end
          else
            if options.schedulers[sched_name.to_sym]
              sched_conf = options.schedulers[sched_name.to_sym]
            else
              raise "Unknown scheduler definition: #{sched_name} for the instance #{instance.canonical_uuid}"
            end
          end

          sched_class = sched_conf.scheduler_class
          sched = sched_class.new(sched_conf.option)

          logger.info("Selected network scheduler: #{sched_name} #{sched_class} for the instance #{instance.canonical_uuid}")
          sched.schedule(instance)
        end
      end
    end
  end
end
