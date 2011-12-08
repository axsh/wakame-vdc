# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      class Chain
        attr_reader :name
        attr_reader :table
        
        def initialize(table,name)
          @table = table
          @name = name
        end
      end
      
      IptablesPreMadeChains = {
          :filter => [:input,:output,:forward],
          :nat => [:prerouting,:postrouting,:output],
          :mangle => [:prerouting,:output,:input,:postrouting],
          :raw => [:prerouting, :output]
      }
      
      class IptablesChain < Chain
        def initialize(table,name)
          raise ArgumentError, "table #{table} doesn't exist. Existing tables are '#{vnet::IptablesPreMadeChains.keys.join(",")}'." unless vnet::IptablesPreMadeChains.keys.member?(table)
          raise ArgumentError, "name can not be any of the following: '#{vnet::IptablesPreMadeChains[table].join(",")}'." if vnet::IptablesPreMadeChains[table].member?(name)
          
          super
        end
      end
      
      EbtablesPreMadeChains = {
          :filter => [:input,:output,:forward],
          :nat => [:prerouting,:postrouting,:output],
          :broute => [:brouting]
      }
      
      class EbtablesChain < Chain
        def initialize(table,name)
          raise ArgumentError, "table #{table} doesn't exist. Existing tables are '#{vnet::EbtablesPreMadeChains.keys.join(",")}'." unless vnet::EbtablesPreMadeChains.keys.member?(table)
          raise ArgumentError, "name can not be any of the following: '#{vnet::EbtablesPreMadeChains[table].join(",")}'." if vnet::EbtablesPreMadeChains[table].member?(name)
          
          super
        end
      end
    
    end
  end
end
