# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      class NetfilterCache < Cache
        def initialize(node)
          # Initialize the values needed to do rpc requests
          @node = node
          @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
        end

        # Makes a call to the database and updates the Cache
        def update
          @cache = @rpc.request('hva-collector', 'get_netfilter_data', @node.node_id)
        end
        
        # Returns the cache
        # if _force_update_ is set to true, the cache will be updated from the database
        def get(force_update = false)
          self.update if @cache.nil? || force_update
          
          @cache
        end
        
        # Adds a newly started instance to the existing cache
        def add_instance(inst_map)
          if @cache.is_a? Array
            @cache << inst_map
          else
          
          end
        end
        
        # Removes a terminated instance from the existing cache
        def remove_instance(inst_id)
          
        end
      end
    
    end
  end
end
