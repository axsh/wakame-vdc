# -*- coding: utf-8 -*-

module Dcmgr
  module Vnet
    module Core

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
          #TODO: properly put together the instance object if it's a uuid or inst_map passed
          #raise ArgumentError, "#{instance} must be an Instance." unless instance.is_a?(Instance)
        end
        
        def remove_instance(instance)
          raise NotImplementedError
          #raise ArgumentError, "#{instance} must be an Instance." unless instance.is_a?(Instance)
        end
        
        def join_security_group(instance,group)
          raise NotImplementedError
          #raise ArgumentError, "#{instance} must be an Instance." unless instance.is_a?(Instance)
          #raise ArgumentError, "#{group} must be a SecurityGroup." unless instance.is_a?(SecurityGroup)
        end
        
        def leave_security_group(instance,group)
          raise NotImplementedError
          #raise ArgumentError, "#{instance} must be an Instance." unless instance.is_a?(Instance)
          #raise ArgumentError, "#{group} must be a SecurityGroup." unless instance.is_a?(SecurityGroup)
        end
        
        def update_security_group(group)
          raise NotImplementedError
          #raise ArgumentError, "#{group} must be a SecurityGroup." unless instance.is_a?(SecurityGroup)
        end
      end
      
      class Rule
        #attr_accessor :rule
        
        #def initialize(rule = nil)
          #self.rule = rule
        #end
      end
      
      class Task
        #Must be an array of rules
        attr_accessor :rules
        
        def initialize
          #@must_before = []
          #@must_after = []
          #@only_apply_if_exists = []
          @rules = []
        end
        
        #def must_before(task = nil)
          #unless task.nil?
            #raise ArgumentError, "Not a task: #{task}." unless task.is_a?(Task)
            #@must_before << task
          #end
          #@must_before
        #end
        
        #def must_after(task = nil)
          #unless task.nil?
            #raise ArgumentError, "Not a task: #{task}." unless task.is_a?(Task)
            #@must_after << task
          #end
          #@must_after
        #end
      end
    
      # Abstract class for task managers to extend
      # A task manager should be able to understand certain rules in a task and be able to apply those
      class TaskManager
        #attr_reader :applied_tasks
      
        #def initialize
          #super
          #@applied_tasks = []
        #end
        
        def apply_task(task)
          #raise ArgumentError, "#{task} is not a Task." unless task.is_a? Task
          #@applied_tasks << task
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
          #raise ArgumentError, "#{task} is not a Task." unless task.is_a? Task
          #raise "#{task} is not applied." unless @applied_tasks.member?(task)
          
          #@applied_tasks.delete(task)
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

      # Abstract class for task managers that apply tasks by vnic to expend
      # This is for task managers that want to apply tasks differently depending on which
      # vnic they're associated with.
      class VnicTaskManager < TaskManager        
        #def intialize
          #super
          #@applied_vnics = []
        #end
        
        def apply_vnic_tasks(vnic_map,tasks)
          #apply_tasks(tasks)
          raise NotImplementedError
        end
        
        # Should remove _tasks_ for this specific vnic if they are applied
        # If no _tasks_ argument is provided, it should remove all tasks for this vnic
        def remove_vnic_tasks(vnic_map,tasks = nil)
          #remove_tasks(tasks)
          raise NotImplementedError
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
end
