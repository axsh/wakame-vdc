# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module Network
      # Meta scheduler calls another scheduler specified by user.
      class PerInstance < NetworkScheduler
        include Dcmgr::Logger
        
        def schedule(instance)
          sched_opts = @options.to_hash || {}
          sched_name = instance.request_params['network_scheduler']
          if sched_name.nil? || sched_name == ''
            if sched_opts.has_key?(:default)
              sched_conf = @options.default
            else
              raise "Missing network_scheduler parameter from the request." 
            end
          else
            if sched_opts.has_key?(sched_name.to_sym)
              sched_conf = @options.send(sched_name.to_sym)
            else
              raise "Unknown scheduler definition: #{sched_name} for the instance #{instance.canonical_uuid}"
            end
          end
          
          sched_class = Scheduler.scheduler_class(sched_conf.scheduler, ::Dcmgr::Scheduler::Network)
          sched = if sched_conf.respond_to?(:options)
                    sched_class.new(sched_conf.options)
                  else
                    sched_class.new
                   end
          logger.info("Selected network scheduler: #{sched_name} #{sched_class} for the instance #{instance.canonical_uuid}")
          sched.schedule(instance)
        end
      end
    end
  end
end
