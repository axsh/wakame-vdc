# -*- coding: utf-8 -*-

module Dcmgr
  module Vnet
    module Netfilter
    
      class IptablesRule < Rule
        attr_accessor :table
        attr_accessor :chain
        attr_accessor :rule
        # Should be either :incoming or :outgoing
        attr_accessor :bound
        attr_accessor :protocol
        
        def initialize(table = nil, chain = nil, protocol = nil, bound = nil, rule = nil)
          super()
          raise ArgumentError, "table does not exist: #{table}" unless vnet::IptablesPreMadeChains.keys.member?(table)
          self.table = table
          self.chain = chain
          self.protocol = protocol
          self.bound = bound
          self.rule = rule
        end
        
        def chain
          if vnet::IptablesPreMadeChains[self.table].member?(@chain)
            @chain.to_s.upcase 
          else
            @chain
          end
        end
        
        # Getter for the protocols iptables supports
        def self.protocols
          {
            'tcp'  => 'tcp',
            'udp'  => 'udp',
            'icmp' => 'icmp',
          }
        end
      end
    
    end
  end
end
