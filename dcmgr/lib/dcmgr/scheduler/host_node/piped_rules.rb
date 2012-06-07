# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      module Rules
        def self.rule_class(input)
          namespace = self
          
          c = case input
              when Symbol
                namespace.const_get(input)
              when String
                if namespace.const_defined?(input)
                  namespace.const_get(input)
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
          
          def filter(datastore)
            raise NotImplementedError
          end
          
          def reorder(array)
            raise NotImplementedError
          end
          
        end
      end

      require 'sequel'
      class PipedRules < HostNodeScheduler
        include Dcmgr::Logger

        configuration do
          DSL do

            def add(rule_name, &blk)
              @config[:rules] ||= []
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

        def schedule(instance)
          host_nodes = ::Dcmgr::Models::HostNode.dataset
          
          options.rules.each { |rule|
            rule_class = rule.scheduler_class
            rule_inst = rule_class.new(rule.option)
            
            logger.debug("Filtering through #{rule_class}")
            
            case host_nodes
              when Sequel::Dataset
                host_nodes = rule_inst.filter(host_nodes,instance)
              when Array
                host_nodes = rule_inst.reorder(host_nodes,instance)
              else
                raise "#{rule} did not return a dataset nor array! Returned: #{host_nodes.class}"
            end
          }
          
          #host_nodes.each { |item|
            #p item
          #}
          
          instance.host_node = host_nodes.first
        end
      end
    end
  end
end
