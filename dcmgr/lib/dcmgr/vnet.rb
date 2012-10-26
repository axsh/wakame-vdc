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

      class NetworkModeNotFoundError < StandardError
      end

      def self.get_mode(mode_name)
        #TODO: Use constants for these names
        case mode_name
        when "securitygroup"
          logger.debug "Selecting SecurityGroup network mode"
          SecurityGroup.new
        #TODO: change to passthrough
        when "passthru"
          logger.debug "Selecting passthrough network mode"
          PassThrough.new
        when "l2overlay"
          logger.info "Warning: e2overlay network mode is not yet implemented. Falling back to SecurityGroup."
          SecurityGroup.new
        else
          #TODO: Load constants to show valid types
          raise NetworkModeNotFoundError, "Network mode #{mode_name} doesn't exist."
        end
      end
    end

  end
end
