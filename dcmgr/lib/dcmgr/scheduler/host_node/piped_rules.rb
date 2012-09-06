# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      module Rules
        def self.rule_class(input)
          namespace = self
          
          c = case input
              when Symbol
                namespace.const_get(input, false)
              when String
                if namespace.const_defined?(input, false)
                  namespace.const_get(input, false)
                else
                  Module.find_const(input)
                end
              when Class
                input
              else
                raise ArgumentError, "Unknown Rule identifier: #{input}"
              end
          c
        end
        
        # Inherit scheduler base to get the configuration ability
        class Rule < Dcmgr::Scheduler::SchedulerBase
          @configuration_class = ::Dcmgr::Configurations::Dcmgr::HostNodeSchedulerRule
          
          def filter(dataset)
            dataset
          end
          
          def reorder(array)
            array
          end
          
        end

        # Basic filter rule which is normally set.
        class Common < Rule
          def filter(dataset,instance)
            dataset.online_nodes.filter(:hypervisor=>instance.hypervisor)
                                        #:arch=>instance.image.arch)
          end
          
          def reorder(array,instance)
            array.select { |hn|
              hn.check_capacity(instance)
            }
          end
        end
      end

      require 'sequel'
      class PipedRules < HostNodeScheduler
        include Dcmgr::Logger

        configuration do
          param :max_results, :default=>100

          on_initialize_hook do
            @config[:rules] = []
          end

          DSL do

            def through(rule_name, &blk)
              c = ::Dcmgr::Scheduler::HostNode::Rules.rule_class(rule_name)
              
              unless c < ::Dcmgr::Scheduler::HostNode::Rules::Rule
                raise "Invalid rule class is set: #{c.to_s}"
              end
              @config[:rules] << ::Dcmgr::Configurations::Dcmgr::HostNodeSchedulerRule::DSL.load_section(
                c,
                ::Dcmgr::Configurations::Dcmgr::HostNodeSchedulerRule,
                &blk
              )

              self
            end
            
          end
        end

        def initialize(*args)
          super
          @rules = options.rules.map { |rule|
            rule_class = rule.scheduler_class
            rule_class.new(rule.option)
          }
p          @rules.unshift(Rules::Common.new(nil))
        end
        
        def schedule(instance)
          # set filter needed commonly.
          hn_ds = ::Dcmgr::Models::HostNode.dataset
          
p          rules = @rules.map { |rule| rule.dup }

          # First pass:
          # Build the dataset filters.
          hn_ds = rules.inject(hn_ds) {|ds, r|
            logger.debug("Filtering through #{r}")
            
            r.filter(ds, instance).tap { |i|
              unless i.is_a?(Sequel::Dataset)
                raise TypeError, "Invalid return type (#{i.class}) from #{r}#filter. Expected Sequel::Dataset."
              end
            }
          }
          logger.debug( hn_ds.limit(options.max_results).sql )
          # Second pass:
          # Run the query from the dataset and continues to process the returned array.
          hn_ary = rules.inject(hn_ds.limit(options.max_results).all) {|ary, r|
            logger.debug("Reordering through #{r}")

            r.reorder(ary, instance).tap { |i|
              unless i.is_a?(::Array)
                raise TypeError, "Invalid return type (#{i.class}) from #{r}#reorder. Expected Array."
              end
            }
          }
          
          raise HostNodeSchedulingError, "No suitable host node found after piping through all rules." if hn_ary.empty?
          
          instance.host_node = hn_ary.first
        end
      end
    end
  end
end
