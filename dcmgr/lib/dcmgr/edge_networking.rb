# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking

    def self.packetfilter_service
      case Dcmgr.conf.sg_implementation
      when "netfilter"
        Netfilter::NetfilterService.new
      when "off"
        # Return the abstract class so no code is executed
        PacketfilterService.new
      end
    end

    module NetworkModes
      include Dcmgr::Logger
      include Dcmgr::Constants::Network

      class NetworkModeNotFoundError < StandardError
      end

      def self.get_mode(mode_name, legacy = false)
        case mode_name
        when NM_SECURITYGROUP
          logger.debug "Selecting #{NM_SECURITYGROUP} network mode"
          legacy ? Legacy::SecurityGroup.new : SecurityGroup.new
        when NM_PASSTHROUGH
          logger.debug "Selecting #{NM_PASSTHROUGH} network mode"
          legacy ? Legacy::PassThrough.new : PassThrough.new
        when NM_L2OVERLAY
          logger.debug "Selecting #{NM_L2OVERLAY} network mode"
          legacy ? Legacy::L2Overlay.new : L2Overlay.new
        else
          raise NetworkModeNotFoundError, "Network mode #{mode_name} doesn't exist. Valid network modes: #{NETWORK_MODES.join(',')}"
        end
      end

      #
      # Legacy netfilter code
      #

      class Task
        #Must be an array of rules
        attr_accessor :rules

        def initialize
          @rules = []
        end

      end

      # Abstract class for task managers to extend
      # A task manager should be able to understand certain rules in a task and be able to apply those
      class TaskManager

        def apply_task(task)
          raise NotImplementedError
        end

        def apply_tasks(tasks)
          raise ArgumentError, "tasks must be an Array of Tasks." unless tasks.is_a?(Array)
          tasks.each { |task|
            next unless task.is_a?(Task)
            apply_task(task)
          }
        end

        def remove_task(task)
          raise NotImplementedError
        end

        #TODO: Change Array to Enumerable
        def remove_tasks(tasks)
          raise ArgumentError, "tasks must be an Array of Tasks." unless tasks.is_a?(Array)
          tasks.each { |task|
            next unless task.is_a?(Task)
            remove_task(task)
          }
        end
      end
    end

  end
end
