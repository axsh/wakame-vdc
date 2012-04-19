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
        
        # Returns the cache
        # if _force_update_ is set to true, the cache will be updated from the database
        def get(force_update = false)
          self.update if @cache.nil? || force_update
          
          # Always return a duplicate of the cache. We don't want any external program messing with the original contents.
          #TODO: Do this in a faster way than marshall
          Marshal.load( Marshal.dump(@cache) )
        end
        
        # Adds a newly started instance to the existing cache
        # Commented out because the cache should be updated from the database instead
        #def add_instance(inst_map)
          #if @cache.is_a? Hash
            #logger.info "adding instance '#{inst_map[:uuid]} to cache'"
            #@cache << inst_map
          #else
          
          #end
        #end
        
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
            local_group[:referenced_groups].find { |group| group[:uuid] == group_id }[:vnics].delete_if { |vnic|
              vnic[:uuid] == vnic_id
            }
          }
        end
        
        private
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
        
      end
      
    end
  end
end
