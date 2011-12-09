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
      
      #IptablesPreMadeChains = {
          #:filter => [:input,:output,:forward],
          #:nat => [:prerouting,:postrouting,:output],
          #:mangle => [:prerouting,:output,:input,:postrouting],
          #:raw => [:prerouting, :output]
      #}
      
      class IptablesChain < Chain
        def initialize(table,name)
          raise ArgumentError, "table #{table} doesn't exist. Existing tables are '#{self.class.pre_made.keys.join(",")}'." unless self.class.pre_made.keys.member?(table)
          raise ArgumentError, "name can not be any of the following: '#{self.class.pre_made[table].join(",")}'." if self.class.pre_made[table].member?(name)
          
          super
        end
        
        def self.pre_made
          {
            :filter => [:input,:output,:forward],
            :nat => [:prerouting,:postrouting,:output],
            :mangle => [:prerouting,:output,:input,:postrouting],
            :raw => [:prerouting, :output]
          }
        end
      end
      
      #EbtablesPreMadeChains = {
          #:filter => [:input,:output,:forward],
          #:nat => [:prerouting,:postrouting,:output],
          #:broute => [:brouting]
      #}
      
      class EbtablesChain < Chain
        def initialize(table,name)
          raise ArgumentError, "table #{table} doesn't exist. Existing tables are '#{self.class.pre_made.keys.join(",")}'." unless self.class.pre_made.keys.member?(table)
          raise ArgumentError, "name can not be any of the following: '#{self.class.pre_made[table].join(",")}'." if self.class.pre_made[table].member?(name)
          
          super
        end
        
        def self.pre_made
          {
            :filter => [:input,:output,:forward],
            :nat => [:prerouting,:postrouting,:output],
            :broute => [:brouting]
          }
        end
      end
    end
  end
end
