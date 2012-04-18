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
          
          self.task_manager.apply_tasks([Dcmgr::VNet::Tasks::DebugIptables.new]) if node.manifest.config.debug_iptables
          
          # Apply the current instances if there are any
          @cache.get[:instances].each { |inst_map|
            logger.info "initializing instance '#{inst_map[:uuid]}'"
            init_instance(inst_map)
          }
        end
        
        def get_instances(instances = nil)
          if instances.nil?
            return @cache.get[:instances]
          elsif instances.is_a?(String)
            return @cache.get[:instances].find { |inst| inst[:uuid] == instances }
          else
            return nil
          end
        end
        
        def get_security_groups(secgs = nil)
          if secgs.nil?
            return @cache.get[:security_groups]
          elsif secgs.is_a?(String)
            return @cache.get[:security_groups].find { |group| group[:uuid] == secgs }
          else
            return nil
          end
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
        end
        
        def join_security_group(vnic,group)
          # Apply isolation tasks for this new vnic to its friends
          local_cache = @cache.get(true) #TODO: Check first if we know this vnic already
          
          # We only need to add isolation rules if it's a foreign vnic
          # Local vnics handle their isolation rules the moment they are created
          unless is_local_vnic?(vnic)
            foreign_vnic_map = local_cache[:security_groups].find {|secg| secg[:uuid] == group}[:foreign_vnics].find {|vnic_map| vnic_map[:uuid] == vnic}
            local_friends = get_local_vnics_in_group(group).delete_if {|friend| friend[:uuid] == vnic}
            
            local_friends.each { |local_vnic_map|
              # Put in the new isolation rules
              self.task_manager.apply_vnic_tasks(local_vnic_map,TaskFactory.create_tasks_for_isolation(local_vnic_map,[foreign_vnic_map],self.node))
            }
          end
        end
        
        def remove_instance(inst_id)
          # Find the instance in the cache
          inst_map = @cache.get[:instances].find { |inst| inst[:uuid] == inst_id}
          
          unless inst_map.nil?
            logger.info "removing instance '#{inst_id}'"
            
            #Clean up the isolation tasks in friends' chains
            inst_map[:vif].each { |vnic|
              next if is_active_vnic?(vnic)

              other_vnics = get_other_vnics(vnic,@cache)
              friends = @isolator.determine_friends(vnic, other_vnics)
              
              friends.each { |friend|
                next if friend[:ipv4].nil? or friend[:ipv4][:network].nil?
                self.task_manager.remove_vnic_tasks(friend,TaskFactory.create_tasks_for_isolation(friend,[vnic],self.node))
              }
            }
            
            inst_map[:vif].each { |vnic|
              next if is_active_vnic?(vnic)

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
        
        def leave_security_group(vnic,group)
          local_cache = @cache.get
          
          # We only need to remove isolation rules if it's a foreign vnic
          if is_foreign_vnic?(vnic) 
            foreign_vnic_map = local_cache[:security_groups].find {|secg| secg[:uuid] == group}[:foreign_vnics].find {|vnic_map| vnic_map[:uuid] == vnic}
            local_friends = get_local_vnics_in_group(group).delete_if {|friend| friend[:uuid] == vnic}
            
            local_friends.each { |local_vnic_map|
              # Put in the new isolation rules
              self.task_manager.remove_vnic_tasks(local_vnic_map,TaskFactory.create_tasks_for_isolation(local_vnic_map,[foreign_vnic_map],self.node))
            }
          end
          
          @cache.remove_foreign_vnic(group,vnic)
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
                
                # Add the new security group tasks
                self.task_manager.apply_vnic_tasks(vnic_map, TaskFactory.create_tasks_for_secgroup(new_group))
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
            "iptables -t raw -F",
            "iptables -t raw -X",
            "iptables -t raw -Z",
          ]
        end
        
        def init_ebtables
          [
              "ebtables -t nat --init-table",
              "ebtables -t filter --init-table",
          ]
        end
        
        def is_local_vnic?(vnic_id)
          local_vnics = @cache.get[:instances].map { |inst_map|
              inst_map[:vif]
            }.flatten
          
          not local_vnics.find {|vnic| vnic[:uuid] == vnic_id}.nil?
        end
        
        def is_foreign_vnic?(vnic_id)
          foreign_vnics = @cache.get[:security_groups].map {|group| group[:foreign_vnics]}.flatten
          
          not foreign_vnics.find {|vnic| vnic[:uuid] == vnic_id}.nil?
        end
        
        def is_active_vnic?(vnic)
          vnic[:ipv4] and vnic[:ipv4][:network]
        end

        def get_local_vnics_in_group(group_id)
          @cache.get[:instances].map { |inst_map|
            inst_map[:vif].delete_if { |vnic_map| not vnic_map[:security_groups].member?(group_id) }
          }.flatten.uniq.compact
        end
        
        def get_foreign_vnics_in_group(group_id)
          @cache.get[:security_groups].find { |group| group[:uuid] == group_id }[:foreign_vnics]
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
            #other_vnics = get_other_vnics(vnic,@cache)
            
            # Determine which vnics need to be isolated from this one
            #friends = @isolator.determine_friends(vnic, other_vnics)
            friends = vnic[:security_groups].map {|group_id| 
              get_local_vnics_in_group(group_id).concat get_foreign_vnics_in_group(group_id)
            }.flatten.uniq
            friends.delete_if {|friend| friend[:uuid] == vnic[:uuid]}
            
            # Determine the security group rules for this vnic
            security_groups = @cache.get[:security_groups].delete_if { |group|
              not vnic[:security_groups].member? group[:uuid]
            }
          
            self.task_manager.apply_vnic_chains(vnic)
            self.task_manager.apply_vnic_tasks(vnic,TaskFactory.create_tasks_for_vnic(vnic,friends,security_groups,node))
            
            # Add isolation tasks to friend vnics
            vnic[:security_groups].each { |group_id|
              get_local_vnics_in_group(group_id).delete_if {|friend| friend[:uuid] == vnic[:uuid]}.each { |friend|
                self.task_manager.apply_vnic_tasks(friend,TaskFactory.create_tasks_for_isolation(friend,[vnic],self.node))
              }
            }
          }
        end
      end
    
    end
  end
end
