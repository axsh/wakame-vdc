# -*- coding: utf-8 -*-

module Dcmgr
  module VNet

    # Abstract class for a Cache implementation to extend
    class Cache
      # Makes a call to the database and updates the Cache
      def update
        raise NotImplementedError
      end
      
      # Returns the cache
      # if _force_update_ is set to true, the cache will be updated from the database
      def get(force_update = false)
        raise NotImplementedError
      end
      
      # Adds a newly started instance to the existing cache
      def add_instance(inst_map)
        raise NotImplementedError
      end
      
      # Removes a terminated instance from the existing cache
      def remove_instance(inst_id)
        raise NotImplementedError
      end
    end
    
    # A controller interface to be implemented
    class Controller
      def apply_instance(instance)
        raise NotImplementedError
      end
      
      def remove_instance(instance)
        raise NotImplementedError
      end
      
      def join_security_group(instance,group)
        raise NotImplementedError
      end
      
      def leave_security_group(instance,group)
        raise NotImplementedError
      end
      
      def update_security_group(group)
        raise NotImplementedError
      end
    end
    
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

    # Abstract class that determines how to isolate instances (vnics) from each other
    class Isolator
      def determine_friends(me,others)
        raise notImplementedError
      end
    end
    
  end
end
