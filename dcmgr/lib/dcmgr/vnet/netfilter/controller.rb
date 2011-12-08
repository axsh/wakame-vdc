# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      class NetfilterController < Controller
        attr_accessor :task_manager
        attr_reader :node
        
        # This controller should use a cache
        
        def initialize(node)
          super()
          @node = node
          
          @cache = NetfilterCache.new(@node)
          
          @isolator = IsolatorFactory.create_isolator
          
          self.task_manager = TaskManagerFactory.create_task_manager(node)
          raise "#{self.task_manager} must be a VnicTaskManager" unless self.task_manager.is_a?(VnicTaskManager)
          
          # Initialize Netfilter configuration
          cmds = []
          cmds << init_iptables if node.manifest.config.enable_iptables
          cmds << init_ebtables if node.manifest.config.enable_ebtables
          cmds.flatten! 
            
          puts cmds.join("\n") if node.manifest.config.verbose_netfilter
          system(cmds.join("\n"))
          
          self.task_manager.apply_tasks([DebugIptables.new]) if node.manifest.config.debug_iptables
          
          #p @cache.get
          
          # Apply the current instances if there are any
          @cache.get[:instances].each { |inst_map|
            self.apply_instance(inst_map)
          }
        end
        
        def apply_instance(instance)
          if instance.is_a? String
            # We got a uuid. Find it in the cache.
            inst_map = @cache.get[:instances].find { |inst| inst[:uuid] == instance}

            # If we couldn't find this instance's uuid in the cache, we update the cache and try again
            if inst_map.nil?
              @cache.update
              inst_map = @cache.get[:instances].find { |inst| inst[:uuid] == instance}
            end
          elsif
            #TODO: When we get something other than a String, make sure it's a Hash
            inst_map = instance
          end
          
          # Call the factory to create all tasks for each vnic. Then apply them
          inst_map[:vif].each { |vnic|
            # Determine which vnics need to be isolated from this one
            friends = @isolator.determine_friends vnic, @cache.get[:instances].map { |inst_map|
              inst_map[:vif].delete_if { |other_vnic|
                other_vnic == vnic
              }
            }.flatten
          
            self.task_manager.apply_vnic_tasks(vnic,TaskFactory.create_tasks_for_vnic(vnic,friends,node))
          }
        end
        
        def remove_instance(inst_id)
          # Call the factory to create all tasks for each vnic. Then remove them
          inst_map = @cache.get[:instances].find { |inst| inst[:uuid] == inst_id}
          
          inst_map[:vif].each { |vnic|
            #TODO: Check if it's really necessary to call the task factory here
            #self.task_manager.remove_vnic_tasks(vnic,TaskFactory.create_tasks_for_vnic(vnic,node))
            self.task_manager.remove_vnic_tasks(vnic)
          }
        end
        
        def join_security_group(instance,group)
          super
        end
        
        def leave_security_group(instance,group)
          super
        end
        
        def update_security_group(group)
          super
        end
        
        private
        def init_iptables
          [
            "iptables -t nat -F",
            "iptables -t nat -X",
            "iptables -t nat -Z",
            "iptables -t filter -F",
            "iptables -t filter -X",
            "iptables -t filter -Z",
            #"iptables -t filter -P FORWARD  DROP"
          ]
        end
        
        def init_ebtables
          [
              "ebtables -t nat --init-table",
              "ebtables -t filter --init-table",
              #"ebtables -t filter -P FORWARD DROP"
          ]
        end
      end
    
    end
  end
end
