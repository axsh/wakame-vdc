# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module OpenFlow
      
      class Flow
        attr_accessor :table
        attr_accessor :priority
        attr_accessor :match
        attr_accessor :actions

        def initialize table, priority, match, actions
          super()
          self.table = table
          self.priority = priority
          self.match = match
          self.actions = actions
        end

        def match_to_s
          str = "table=#{table},priority=#{priority}"

          match.each { |key,value|
            tag = match_tags[key]
            raise "No match tag: key:#{key.inspect}" if tag.nil?

            str << "," << tag % value
          }
          str
        end

        # Note; the Hash objects before ruby 1.9 do not maintain order
        # of insertion when iterating, so the actions will be reordered.
        #
        # As the action list is order-sensetive the action list won't
        # be strictly correct in earlier versions of ruby, however we
        # don't currently use any such flows.
        def actions_to_s
          str = ""

          actions.each { |key,value|
            tag = action_tags[key]
            raise "No action tag: key:#{key.inspect}" if tag.nil?

            str << "," << tag % value
          }
          str
        end

        def match_tags
          {
            :arp => 'arp',
            :dl_dst => 'dl_dst=%s',
            :dl_src => 'dl_src=%s',
            :nw_dst => 'nw_dst=%s',
            :nw_src => 'nw_src=%s',
            :tp_dst => 'tp_dst=%s',
            :tp_src => 'tp_src=%s',
            :reg1 => 'reg1=%i',
            :reg2 => 'reg2=%i',
            :tcp => 'tcp',
            :udp => 'udp',
          }
        end

        def action_tags
          {
            :controller => 'controller',
            :learn => 'learn(%s)',
            :nw_dst => 'mod_nw_dst',
            :resubmit => 'resubmit(,%i)',
          }
        end

      end

    end
  end
end
