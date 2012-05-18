# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      class NetfilterCache < Cache
        include Dcmgr::Logger
        
        def initialize(node)
          # Initialize the values needed to do rpc requests
          @node = node
          @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
        end

        # Makes a call to the database and updates the Cache
        def update
          logger.info "updating cache from database"
          @cache = @rpc.request('hva-collector', 'get_netfilter_data', @node.node_id)

          #Return nil to avoid the cache being returned by reference
          nil
        end
        
        def update_rules(group_id)
          if @cache.nil?
            self.update
          else
            group = get_group(group_id)
            raise "Unknown security group: #{group_id}" if group.nil?
            group[:rules] = @rpc.request('hva-collector', 'get_rules_of_security_group', group_id)
            group[:referencees] = @rpc.request('hva-collector', 'get_referencees_of_security_group', group_id)
          end
          
          nil
        end
        
        def update_referencers(group_id)
          if @cache.nil?
            self.update
          else
            group = get_group(group_id)
            raise "Unknown security group: #{group_id}" if group.nil?
            group[:referencers] = @rpc.request('hva-collector', 'get_referencers_of_security_group', group_id)
          end
          
          nil
        end
        
        # Returns the cache
        # if _force_update_ is set to true, the cache will be updated from the database
        def get(force_update = false)
          self.update if @cache.nil? || force_update
          
          # Always return a duplicate of the cache. We don't want any external program messing with the original contents.
          deep_clone(@cache)
        end
        
        # Removes a terminated instance from the existing cache
        def remove_instance(inst_id)
          inst = @cache[:instances].find { |inst_map|
            inst_map[:uuid] == inst_id
          }
          
          logger.info "removing Instance '#{inst_id}' from cache"
          @cache[:instances].delete(inst)
          
          # Delete the security group if this was the last vnic in it
          inst[:vif].each { |vif|
            vif[:security_groups].each { |secg_id|
              delete_group(secg_id) unless instances_left_in_group?(secg_id)
            }
          }
        end
        
        def remove_foreign_vnic(group_id,vnic_id)
          group = @cache[:security_groups].find { |group| group[:uuid] == group_id }
          group[:foreign_vnics].delete_if { |vnic| vnic[:uuid] == vnic_id} unless group.nil?
        end
        
        def remove_referenced_vnic(group_id,vnic_id)
          group = @cache[:security_groups].each {|local_group| 
            ref_group = local_group[:referencees].find { |group| group[:uuid] == group_id }
            ref_group[:vnics].delete_if { |vnic|
              vnic[:uuid] == vnic_id
            } unless ref_group.nil?
          }
        end
        
        def remove_local_vnic_from_security_group(group_id,vnic_id)
          instance = @cache[:instances].find { |inst_map|
            not inst_map[:vif].find {|vif_map| vif_map[:uuid] == vnic_id }.nil?
          }
          
          unless instance.nil?
            instance[:security_groups].delete(group_id)
            instance[:vif].find {|vif_map| vif_map[:uuid] == vnic_id }[:security_groups].delete(group_id)
            
            delete_group(group_id) unless instances_left_in_group?(group_id)
          end
        end
        
        private
        def deep_clone(something)
          Marshal.load( Marshal.dump(something) )
        end
        
        # Returns true if there are still instances left in this security group on this host
        def instances_left_in_group?(group_id)
          other_vnics = @cache[:instances].map { |inst_map|
            inst_map[:vif].find { |vif|
              vif[:security_groups].member?(group_id)
            }
          }.flatten.uniq.compact
          
          not other_vnics.empty?
        end

        def delete_group(group_id)
          logger.info "deleting #{group_id} from cache"
          @cache[:security_groups].delete_if {|group| group[:uuid] == group_id}
        end
        
        def get_group(group_id)
          @cache[:security_groups].find {|g| g[:uuid] == group_id}
        end
        
        def get_vnic(vnic_id)
          instance = @cache[:instances].find {|i|  i[:vif].find {|v| v[:uuid] == vnic_id } }
          
          instance[:vif].find {|v| v[:uuid] == vnic_id} unless instance.nil?
        end
        
      end
      
    end
  end
end
