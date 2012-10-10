# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter

      class EbtablesRule
        attr_accessor :table
        attr_accessor :chain
        attr_accessor :rule
        # Should be either :incoming or :outgoing
        attr_accessor :bound
        attr_accessor :protocol

        def initialize(table = nil, chain = nil,  protocol = nil, bound = nil, rule = nil)
          super()
          raise ArgumentError, "table does not exist: #{table}" unless EbtablesChain.pre_made.keys.member?(table)
          self.table = table
          self.chain = chain
          self.protocol = protocol
          self.bound = bound
          self.rule = rule
        end

        # Override the chain getter to allow us to handle premade chains
        # with symbols instead of all caps strings. ie, :forward instead of "FORWARD"
        def chain
          if EbtablesChain.pre_made[self.table].member?(@chain)
            @chain.to_s.upcase
          else
            @chain
          end
        end

        # Little static method that returns the part of an ebtables rule required for logging arp
        def self.log_arp(prefix)
          "--log-ip --log-arp --log-prefix '#{prefix}'"
        end

        # Getter for a hashmap of ebtables protocols
        def self.protocols
          {
            'ip4'  => 'ip4',
            'arp'  => 'arp',
            #'ip6'  => 'ip6',
            #'rarp' => '0x8035',
          }
        end
      end

    end
  end
end
