# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module OpenFlow
      
      # A class to indicate the match/etc is a placeholder?
      class FlowPlaceholder
        attr_accessor :index

        def initialize index
          @index = index
        end
      end

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

        def match_sparse_to_s
          str = "table=#{table}"

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
          if actions.class == Array
            str = ""
            actions.each { |block|
              str << actions_block_to_s(block)
            }
            str
          else
            actions_block_to_s actions
          end
        end

        def actions_block_to_s block, arg = nil
          str = ""

          block.each { |key,value|
            tag = action_tags[key]
            raise "No action tag: key:#{key.inspect}" if tag.nil?

            if value.class == FlowPlaceholder
              str << "," << tag % arg
            else
              str << "," << tag % value
            end
          }
          str
        end

        def flood_actions_to_s args
          str = ""

          args.each { |arg|
            if actions.class == Array
              actions.each { |block|
                str << actions_block_to_s(block, arg)
              }
            else
              str << actions_block_to_s(actions, arg)
            end
          }
          str
        end

        def match_tags
          {
            :ip => 'ip',
            :arp => 'arp',
            :icmp => 'icmp',
            :tcp => 'tcp',
            :udp => 'udp',
            :dl_dst => 'dl_dst=%s',
            :dl_src => 'dl_src=%s',
            :dl_type => 'dl_type=0x%x',
            :nw_dst => 'nw_dst=%s',
            :nw_src => 'nw_src=%s',
            :nw_proto => 'nw_proto=%i',
            :tp_dst => 'tp_dst=%s',
            :tp_src => 'tp_src=%s',
            :arp_sha => 'arp_sha=%s',
            :arp_tha => 'arp_tha=%s',
            :in_port => 'in_port=%i',
            :reg1 => 'reg1=%i',
            :reg2 => 'reg2=%i',

            # Not really match tags, separate.
            :idle_timeout => 'idle_timeout=%i',
          }
        end

        def action_tags
          {
            :controller => 'controller',
            :drop => 'drop',
            :learn => 'learn(%s)',
            :local => 'local',
            :load_reg0 => 'load:%i->NXM_NX_REG0[]',
            :load_reg1 => 'load:%i->NXM_NX_REG1[]',
            :load_reg2 => 'load:%i->NXM_NX_REG2[]',
            :mod_dl_dst => 'mod_dl_dst',
            :mod_dl_src => 'mod_dl_src',
            :mod_nw_dst => 'mod_nw_dst',
            :mod_nw_src => 'mod_nw_src',
            :mod_tp_dst => 'mod_tp_dst',
            :mod_tp_src => 'mod_tp_src',
            :output => 'output:%i',
            :output_reg0 => 'output:NXM_NX_REG0[]',
            :output_reg1 => 'output:NXM_NX_REG1[]',
            :output_reg2 => 'output:NXM_NX_REG2[]',
            :resubmit => 'resubmit(,%i)',
          }
        end
      end

    end
  end
end

