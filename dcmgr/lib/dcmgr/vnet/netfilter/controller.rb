# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      class NetfilterController < Controller
        include Dcmgr::Logger
        attr_accessor :task_manager
        attr_reader :node
        
        # This controller should use a cache
        
        def initialize(node)
          logger.info "initializing controller"
          super()
          @node = node
          
          @cache = NetfilterCache.new(@node)
          
          @isolator = IsolatorFactory.create_isolator
          
          self.task_manager = TaskManagerFactory.create_task_manager(node)
          raise "#{self.task_manager} must be a NetfilterTaskManager" unless self.task_manager.is_a?(NetfilterTaskManager)
          
          # Initialize Netfilter configuration
          cmds = []
          cmds << init_iptables if node.manifest.config.enable_iptables
          cmds << init_ebtables if node.manifest.config.enable_ebtables
          cmds.flatten! 
            
          puts cmds.join("\n") if node.manifest.config.verbose_netfilter
          system(cmds.join("\n"))
          
          self.task_manager.apply_tasks([DebugIptables.new]) if node.manifest.config.debug_iptables
          
          # Apply the current instances if there are any
          @cache.get[:instances].each { |inst_map|
            logger.info "initializing instance '#{inst_map[:uuid]}'"
            self.init_instance(inst_map)
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
          elsif instance.is_a? Hash
            inst_map = instance
          else
            raise ArgumentError, "instance must be either a uuid or an instance's hash map" unless instance.is_a? Hash
          end
          
          logger.info "applying instance '#{inst_map[:uuid]}'"
          
          # Create all the rules for this instance
          init_instance(inst_map)
          
          # Apply isolation tasks for this new instance to its friends
          inst_map[:vif].each { |vnic|
            other_vnics = get_other_vnics(vnic,@cache)
            # Determine which vnics need to be isolated from this one
            friends = @isolator.determine_friends(vnic, other_vnics)
            
            friends.each { |friend|
              # Remove the drop rules so the isolation rules don't ger applied after them
              #self.task_manager.remove_vnic_tasks(friend,TaskFactory.create_drop_tasks_for_vnic(friend,self.node))
              
              # Put in the new isolation rules
              self.task_manager.apply_vnic_tasks(friend,TaskFactory.create_tasks_for_isolation(friend,[vnic],self.node))
              # Put the drop rules back
              #self.task_manager.apply_vnic_tasks(friend,TaskFactory.create_drop_tasks_for_vnic(friend,self.node))
            }
          }
        end
        
        def get_other_vnics(vnic,cache)
          cache.get[:instances].map { |inst_map|
              inst_map[:vif].delete_if { |other_vnic|
                other_vnic == vnic
            }
          }.flatten
        end
        
        def init_instance(inst_map)
          # Call the factory to create all tasks for each vnic. Then apply them
          inst_map[:vif].each { |vnic|
            # Get a list of all other vnics in this host
            other_vnics = get_other_vnics(vnic,@cache)
            
            # Determine which vnics need to be isolated from this one
            friends = @isolator.determine_friends(vnic, other_vnics)
            
            # Determine the security group rules for this vnic
            security_groups = @cache.get[:security_groups].delete_if { |group|
              not vnic[:security_groups].member? group[:uuid]
            }
          
            self.task_manager.apply_vnic_chains(vnic)
            self.task_manager.apply_vnic_tasks(vnic,TaskFactory.create_tasks_for_vnic(vnic,friends,security_groups,node))
          }
        end
        
        def remove_instance(inst_id)
          # Find the instance in the cache
          inst_map = @cache.get[:instances].find { |inst| inst[:uuid] == inst_id}
          
          unless inst_map.nil?
            logger.info "removing instance '#{inst_id}'"
            
            #Clean up the isolation tasks in friends' chains
            inst_map[:vif].each { |vnic|
              other_vnics = get_other_vnics(vnic,@cache)
              friends = @isolator.determine_friends(vnic, other_vnics)
              
              friends.each { |friend|
                self.task_manager.remove_vnic_tasks(friend,TaskFactory.create_tasks_for_isolation(friend,[vnic],self.node))
              }
            }
            
            inst_map[:vif].each { |vnic|
              # Removing the nat tasks separately because they include an arp reply
              # that isn't put in a separate chain
              other_vnics = get_other_vnics(vnic,@cache)
              # Determine which vnics need to be isolated from this one
              friends = @isolator.determine_friends(vnic, other_vnics)
              
              self.task_manager.remove_vnic_tasks(vnic, TaskFactory.create_nat_tasks_for_vnic(vnic,self.node) )
              self.task_manager.remove_vnic_chains(vnic)
            }
            
            # Remove the terminated instance from the cache
            @cache.remove_instance(inst_id)
          end
        end
        
        def update_security_group(group)
          logger.info "updating security group '#{group}'"
          # Get the old security group info from the cache
          old_cache = @cache.get
          
          # Get a list of vnics that are in this security group
          vnics = old_cache[:instances].map {|inst_map| inst_map[:vif].delete_if { |vnic| not vnic[:security_groups].member?(group) } }.flatten
          unless vnics.empty?
            # Get the rules for this security group
            old_group = old_cache[:security_groups].find {|sg| sg[:uuid] == group}
          
            # Get the new info from the cache
            new_cache = @cache.get(true)
            new_group = new_cache[:security_groups].find {|sg| sg[:uuid] == group}
            
            unless old_group.nil? || new_group.nil?
              vnics.each { |vnic_map|
                # Remove the old security group tasks
                self.task_manager.remove_vnic_tasks(vnic_map, TaskFactory.create_tasks_for_secgroup(old_group))
                
                # Remove the drop tasks so the new group's tasks don't get applied behind it
                #self.task_manager.remove_vnic_tasks(vnic_map, TaskFactory.create_drop_tasks_for_vnic(vnic_map,self.node))
                # Add the new security group tasks
                self.task_manager.apply_vnic_tasks(vnic_map, TaskFactory.create_tasks_for_secgroup(new_group))
                # Put the drop tasks back in place
                #self.task_manager.apply_vnic_tasks(vnic_map, TaskFactory.create_drop_tasks_for_vnic(vnic_map,self.node))
              }
            end
          end
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
