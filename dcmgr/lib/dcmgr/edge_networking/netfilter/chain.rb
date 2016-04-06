# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Netfilter

      class Chain
        attr_reader :name
        attr_reader :table

        def initialize(table,name)
          @table = table
          @name = name
        end

        # Determines which packets should be led into this chain
        def jumps
          raise NotImplementedError
        end

        # Determines which rules should be applied to this chain
        # Returns a tailored rule without affecting the original rule
        def tailor(rule)
          tailor!(rule.dup)
        end

        # Determines which rules should be applied to this chain
        # Tailors and returns the original rule
        def tailor!(rule)
          raise NotImplementedError
        end
      end

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
