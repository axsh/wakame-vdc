# -*- coding: utf-8 -*-

module Dcmgr
  module VNet

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

    module NetworkModes
      include Dcmgr::Logger
      include Dcmgr::Constants::Network

      class NetworkModeNotFoundError < StandardError
      end

      def self.get_mode(mode_name)
        case mode_name
        when NM_SECURITYGROUP
          logger.debug "Selecting #{NM_SECURITYGROUP} network mode"
          SecurityGroup.new
        when NM_PASSTHROUGH
          logger.debug "Selecting #{NM_PASSTHROUGH} network mode"
          PassThrough.new
        when NM_L2OVERLAY
          logger.debug "Selecting #{NM_L2OVERLAY} network mode"
          L2Overlay.new
        else
          raise NetworkModeNotFoundError, "Network mode #{mode_name} doesn't exist. Valid network modes: #{NETWORK_MODES.join(',')}"
        end
      end
    end

  end
end
