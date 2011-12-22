# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      # Abstract class for task managers that apply netfilter to extend.
      # These have extra methods to create custom chains depending on vnic.
      # Tasks can then be applied to these custom chains.
      class NetfilterTaskManager < TaskManager        
        
        def apply_vnic_chains(vnic_map)
          raise NotImplementedError
        end
        
        def apply_vnic_tasks(vnic_map,tasks)
          raise NotImplementedError
        end
        
        # Should remove _tasks_ for this specific vnic if they are applied
        def remove_vnic_tasks(vnic_map,tasks = nil)
          raise NotImplementedError
        end
        
        def remove_vnic_chains(vnic_map)
          raise NotImplementedError
        end
      end
    
      # Task manager that creates chains based on vif uuid and protocol
      # Supports ebtables rules and iptables rules
      class VNicProtocolTaskManager < NetfilterTaskManager
        include Dcmgr::Helpers::NicHelper
        # These store the protocols used by iptables and ebtables
        attr_reader :iptables_protocols
        attr_reader :ebtables_protocols
        # These are flags that decide whether or not iptables and ebtables are enabled
        attr_accessor :enable_iptables
        attr_accessor :enable_ebtables
        # Flag that decides whether or not we output commands that are applied
        attr_accessor :verbose_commands
        
        def initialize
          super
          @iptables_protocols = IptablesRule.protocols
          @ebtables_protocols = EbtablesRule.protocols
        end
        
        def iptables_chains(vnic_map)
          chains = []
          
          [ 's', 'd' ].each { |bound|
            self.iptables_protocols.each { |k,v|
                chains << IptablesChain.new(:filter, "#{bound}_#{vnic_map[:uuid]}")
                chains << IptablesChain.new(:filter, "#{bound}_#{vnic_map[:uuid]}_#{k}")

                chains << IptablesChain.new(:filter, "#{bound}_#{vnic_map[:uuid]}_drop")
                chains << IptablesChain.new(:filter, "#{bound}_#{vnic_map[:uuid]}_#{k}_drop")
            }
            
            #[ 'pre', 'post'].each { |nat_chain|
              #chains << IptablesChain.new(:nat, "#{bound}_#{vnic_map[:uuid]}_#{nat_chain}")
            #}
          }
          #chains << IptablesChain.new(:nat, "#{vnic_map[:uuid]}_dnat_exceptions")
          chains << IptablesChain.new(:nat, "#{vnic_map[:uuid]}_snat_exceptions")
          
          chains
        end
        
        def iptables_forward_chain_jumps(vnic)
          jumps = []
          
          #Main jumps from the forward chains
          jumps << IptablesRule.new(:filter,:forward,nil,nil,"-m physdev --physdev-is-bridged --physdev-in  #{vnic[:uuid]} -j s_#{vnic[:uuid]}")
          jumps << IptablesRule.new(:filter,:forward,nil,nil,"-m physdev --physdev-is-bridged --physdev-out #{vnic[:uuid]} -j d_#{vnic[:uuid]}")
          
          jumps
        end
        
        def iptables_protocol_chain_jumps(vnic)
          jumps = []
          
          [ 's', 'd' ].each do |bound|
            self.iptables_protocols.each { |k,v|
              case k
              when 'tcp'
                case bound
                when 's'
                  jumps << IptablesRule.new(:filter,"#{bound}_#{vnic[:uuid]}",nil,:outgoing,"-m state --state NEW,ESTABLISHED -p #{k} -j #{bound}_#{vnic[:uuid]}_#{k}")
                when 'd'
                  jumps << IptablesRule.new(:filter,"#{bound}_#{vnic[:uuid]}",nil,:incoming,"-p #{k} -j #{bound}_#{vnic[:uuid]}_#{k}")
                end
              when 'udp'
                case bound
                when 's'
                  jumps << IptablesRule.new(:filter,"#{bound}_#{vnic[:uuid]}",nil,:outgoing,"-m state --state NEW,ESTABLISHED -p #{k} -j #{bound}_#{vnic[:uuid]}_#{k}")
                when 'd'
                  jumps << IptablesRule.new(:filter,"#{bound}_#{vnic[:uuid]}",nil,:incoming,"-p #{k} -j #{bound}_#{vnic[:uuid]}_#{k}")
                end
              when 'icmp'
                case bound
                when 's'
                  jumps << IptablesRule.new(:filter,"#{bound}_#{vnic[:uuid]}",nil,:outgoing,"-m state --state NEW,ESTABLISHED,RELATED -p #{k} -j #{bound}_#{vnic[:uuid]}_#{k}")
                when 'd'
                  jumps << IptablesRule.new(:filter,"#{bound}_#{vnic[:uuid]}",nil,:incoming,"-p #{k} -j #{bound}_#{vnic[:uuid]}_#{k}")
                end
              end
            }
          end
          
          jumps
        end
        
        # Returns the rules that direct packets for a vnic to that specific vnic's custom nat chains
        def iptables_nat_chain_jumps(vnic_map)
          jumps = []
          
          #[ :prerouting, :postrouting].each { |chain|
          #jumps << IptablesRule.new(:nat,:prerouting,nil,nil,"-d #{vnic_map[:ipv4][:nat_address]} -j #{vnic_map[:uuid]}_dnat_exceptions")
          jumps << IptablesRule.new(:nat,:postrouting,nil,nil,"-s #{vnic_map[:ipv4][:address]} -j #{vnic_map[:uuid]}_snat_exceptions")
          #}
          
          #jumps << IptablesRule.new(:nat,:prerouting,nil,nil,"-m physdev --physdev-in  #{vnic[:uuid]} -j s_#{vnic[:uuid]}_pre")
          #jumps << IptablesRule.new(:nat,:prerouting,nil,nil,"-m physdev --physdev-out  #{vnic[:uuid]} -j d_#{vnic[:uuid]}_pre")
          #jumps << IptablesRule.new(:nat,:postrouting,nil,nil,"-m physdev --physdev-in #{vnic[:uuid]} -j s_#{vnic[:uuid]}_post")
          #jumps << IptablesRule.new(:nat,:postrouting,nil,nil,"-m physdev --physdev-out #{vnic[:uuid]} -j d_#{vnic[:uuid]}_post")
          
          jumps
        end
        
        def ebtables_chains(vnic)
          chains = []
          
          chains << EbtablesChain.new(:filter, "s_#{vnic[:uuid]}")
          chains << EbtablesChain.new(:filter, "d_#{vnic[:uuid]}")
          chains << EbtablesChain.new(:filter, "s_#{vnic[:uuid]}_d_hst")
          chains << EbtablesChain.new(:filter, "d_#{vnic[:uuid]}_s_hst")
          self.ebtables_protocols.each { |k,v|
            chains << EbtablesChain.new(:filter, "s_#{vnic[:uuid]}_#{k}")
            chains << EbtablesChain.new(:filter, "d_#{vnic[:uuid]}_#{k}")
            chains << EbtablesChain.new(:filter, "s_#{vnic[:uuid]}_d_hst_#{k}")
            chains << EbtablesChain.new(:filter, "d_#{vnic[:uuid]}_s_hst_#{k}")
          }
          
          chains
        end
        
        def ebtables_forward_chain_jumps(vnic)
          jumps = []
          
          jumps << EbtablesRule.new(:filter,:forward,nil,nil,"-i #{vnic[:uuid]} -j s_#{vnic[:uuid]}")
          jumps << EbtablesRule.new(:filter,:forward,nil,nil,"-o #{vnic[:uuid]} -j d_#{vnic[:uuid]}")
          
          jumps
        end
        
        def ebtables_protocol_chain_jumps(vnic)
          jumps = []
          
          self.ebtables_protocols.each { |k,v|
            jumps << EbtablesRule.new(:filter,"s_#{vnic[:uuid]}",nil,:outgoing,"-p #{v} -j s_#{vnic[:uuid]}_#{k}")
            jumps << EbtablesRule.new(:filter,"d_#{vnic[:uuid]}",nil,:incoming,"-p #{v} -j d_#{vnic[:uuid]}_#{k}")
            jumps << EbtablesRule.new(:filter,"s_#{vnic[:uuid]}_d_hst",nil,:outgoing,"-p #{v} -j s_#{vnic[:uuid]}_d_hst_#{k}")
            jumps << EbtablesRule.new(:filter,"d_#{vnic[:uuid]}_s_hst",nil,:incoming,"-p #{v} -j d_#{vnic[:uuid]}_s_hst_#{k}")
          }
          
          jumps
        end
        
        def ebtables_input_chain_jumps(vnic)
          jumps = []
          
          jumps << EbtablesRule.new(:filter,:input,nil,:outgoing,"-i #{vnic[:uuid]} -j s_#{vnic[:uuid]}_d_hst")
          
          jumps
        end
        
        def ebtables_output_chain_jumps(vnic)
          jumps = []
          
          jumps << EbtablesRule.new(:filter,:output,nil,:incoming,"-o #{vnic[:uuid]} -j d_#{vnic[:uuid]}_s_hst")
          
          jumps
        end
        
        #Returns commands for creating iptables chains and their jump rules
        def get_iptables_chains_apply_commands(vnic_map)
          commands = []
          
          commands << iptables_chains(vnic_map).map { |chain| "iptables -t #{chain.table} -N #{chain.name}"}
          
          create_jump_block = Proc.new { |jump| 
            "iptables -t #{jump.table} -A #{jump.chain} #{jump.rule}"
          }
          
          commands << iptables_forward_chain_jumps(vnic_map).map(&create_jump_block)
          commands << iptables_nat_chain_jumps(vnic_map).map(&create_jump_block)
          commands << iptables_protocol_chain_jumps(vnic_map).map(&create_jump_block)
          
          commands.flatten.uniq
        end
        
        # Apply the custom iptables chains for this vnic
        # This method only applies the chains and doesn't make any rules
        def apply_iptables_chains(vnic_map)
          cmds = get_iptables_chains_apply_commands(vnic_map)
          puts cmds.join("\n") if self.verbose_commands
          system(cmds.join("\n"))
        end
        
        def remove_iptables_chains(vnic)
          cmds = get_iptables_chains_remove_commands(vnic)
          puts cmds.join("\n") if self.verbose_commands
          system(cmds.join("\n"))
        end
        
        def get_iptables_chains_remove_commands(vnic_map)
          commands = []
          
          delete_jump_block = Proc.new {|jump| "iptables -t #{jump.table} -D #{jump.chain} #{jump.rule}"}
          
          commands << iptables_forward_chain_jumps(vnic_map).map(&delete_jump_block)
          commands << iptables_nat_chain_jumps(vnic_map).map(&delete_jump_block)
          
          commands << iptables_chains(vnic_map).map {|chain| 
            ["iptables -t #{chain.table} -F #{chain.name}","iptables -t #{chain.table} -X #{chain.name}"]
          }
          
          commands.flatten.uniq
        end
        
        def apply_ebtables_chains(vnic_map)
          cmds = get_ebtables_chains_apply_commands(vnic_map)
          puts cmds.join("\n") if self.verbose_commands
          system(cmds.join("\n"))
        end
        
        def get_ebtables_chains_apply_commands(vnic_map)
          commands = []
          
          commands << ebtables_chains(vnic_map).map {|chain| ["ebtables -t #{chain.table} -N #{chain.name}","ebtables -t #{chain.table} -P #{chain.name} RETURN"]}#,"ebtables -t #{chain.table} -P #{chain.name} DROP"]}
          
          create_jump_block = Proc.new {|jump| "ebtables -t #{jump.table} -A #{jump.chain} #{jump.rule}"}
          
          commands << ebtables_forward_chain_jumps(vnic_map).map(&create_jump_block)
          commands << ebtables_input_chain_jumps(vnic_map).map(&create_jump_block)
          commands << ebtables_output_chain_jumps(vnic_map).map(&create_jump_block)
          commands << ebtables_protocol_chain_jumps(vnic_map).map(&create_jump_block)
          
          commands.flatten.uniq
        end
        
        def remove_ebtables_chains(vnic)
          cmds = get_ebtables_chains_remove_commands(vnic)
          puts cmds.join("\n") if self.verbose_commands
          system(cmds.join("\n"))
        end
        
        def get_ebtables_chains_remove_commands(vnic_map)
          commands = []
          
          delete_jump_block = Proc.new {|jump| "ebtables -t #{jump.table} -D #{jump.chain} #{jump.rule}"}
          
          commands << ebtables_forward_chain_jumps(vnic_map).map(&delete_jump_block)
          commands << ebtables_input_chain_jumps(vnic_map).map(&delete_jump_block)
          commands << ebtables_output_chain_jumps(vnic_map).map(&delete_jump_block)
          
          commands << ebtables_chains(vnic_map).map {|chain|
            ["ebtables -t #{chain.table} -F #{chain.name}","ebtables -t #{chain.table} -X #{chain.name}"]
          }
          
          commands.flatten.uniq
        end
        
        # Jumps to custom chains named after the vnic's uuid,
        # then jumps to more custom chains based on the protocol used.
        # In those the real netfiltering happens
        def apply_vnic_tasks(vnic_map, tasks)
          # Apply the tasks to our chains
          apply_tasks(tailor_vnic_tasks(vnic_map,tasks))
        end
        
        def apply_vnic_chains(vnic_map)
          apply_iptables_chains(vnic_map) if self.enable_iptables
          apply_ebtables_chains(vnic_map) if self.enable_ebtables
        end
        
        # Translates _rule_ into a command that can be directly passed on to the OS
        # _action_ determines if the command must _:apply_ or _:remove_ a rule. 
        def get_rule_command(rule,action)
          actions = {:apply => "I", :remove => "D"}
          raise ArgumentError, "#{rule} is not a Rule" unless rule.is_a? Rule
          raise ArgumentError, "action must be one of the following: '#{actions.keys.join(",")}'" unless actions.member? action
          
          if rule.is_a?(IptablesRule) && self.enable_iptables
            "iptables -t #{rule.table} -#{actions[action]} #{rule.chain} #{rule.rule}"
          elsif rule.is_a?(EbtablesRule) && self.enable_ebtables
            "ebtables -t #{rule.table} -#{actions[action]} #{rule.chain} #{rule.rule}"
          else
            nil
          end
        end
        
        def apply_tasks(tasks)
          commands = []

          commands = tasks.map { |task|
            next unless task.is_a? Task
            task.rules.map { |rule|
              next unless rule.is_a? Rule
              get_rule_command(rule,:apply)
            }
          }
          
          final_commands = commands.flatten.uniq.compact
          puts final_commands.join("\n") if self.verbose_commands
          
          system(final_commands.join("\n"))
        end
        
        def remove_tasks(tasks)
          commands = []
          
          commands = tasks.map { |task|
            next unless task.is_a? Task
            task.rules.map { |rule|
              get_rule_command(rule,:remove)
            }
          }
          
          final_commands = commands.flatten.uniq.compact
          puts final_commands.join("\n") if self.verbose_commands
          
          system(final_commands.join("\n"))
        end
        
        # Changes the chains of each rule in _tasks_ to match this TaskManager's model 
        def tailor_vnic_tasks(vnic,tasks)
          bound = {:incoming => "d", :outgoing => "s"}
          nat_chains = {"PREROUTING" => "pre", "POSTROUTING" => "post"}

          # Use the marshal trick to make a deep copy of tasks
          new_tasks = Marshal.load( Marshal.dump(tasks) )

          new_tasks.each { |task|
            # For protocol independent tasks, generate a copy of their rules for each protocol
            # This is needed because this task manager uses custom chains for each protocol
            task.rules = task.rules.map { |rule|
              if rule.protocol.nil?
                rule.class.protocols.values.map { |prot|
                  new_rule = rule.dup
                  new_rule.protocol = prot
                  new_rule
                }
              else
                rule
              end
            }.flatten
          
            task.rules.each { |rule|
              # Direct iptables rules to their vnic's custom chains
              if rule.is_a?(IptablesRule) && self.enable_iptables
                case rule.table
                  when :nat
                    case rule.chain
                      when :prerouting.to_s.upcase then
                        #unless rule.rule.include? "-j DNAT"
                          #rule.chain = "#{vnic[:uuid]}_dnat_exceptions"
                        #end
                        #p rule.chain
                        #rule.chain = "#{bound[rule.bound]}_#{vnic[:uuid]}_#{nat_chains[rule.chain]}"
                        #p rule.chain
                      when :postrouting.to_s.upcase then
                        # Very hackish but should work for now
                        unless rule.rule.include? "-j SNAT"
                          rule.chain = "#{vnic[:uuid]}_snat_exceptions"
                        end
                        #rule.chain = "#{bound[rule.bound]}_#{vnic[:uuid]}_#{nat_chains[rule.chain]}"
                    end
                  when :filter
                    case rule.chain
                      when :forward.to_s.upcase then
                        rule.chain = "#{bound[rule.bound]}_#{vnic[:uuid]}_#{rule.protocol}"
                    end
                end
              # Direct ebtables rules to their vnic's custom chains
              elsif rule.is_a?(EbtablesRule) && self.enable_ebtables
                case rule.table
                  when :filter then
                    case rule.chain
                      when :input.to_s.upcase then
                        rule.chain = "s_#{vnic[:uuid]}_d_hst_#{rule.protocol}"
                      when :output.to_s.upcase then
                        rule.chain = "d_#{vnic[:uuid]}_s_hst_#{rule.protocol}"
                      when :forward.to_s.upcase then
                        rule.chain = "#{bound[rule.bound]}_#{vnic[:uuid]}_#{rule.protocol}"
                    end
                end
              end
            }
          }
          
          new_tasks
        end
        
        # Removes _tasks_ for this specific vnic if they are applied
        # If no _tasks_ argument is provided, all tasks for this vnic will be removed
        def remove_vnic_tasks(vnic,tasks = nil)
            remove_tasks(tailor_vnic_tasks(vnic,tasks))
        end
        
        def remove_vnic_chains(vnic)
          remove_iptables_chains(vnic) if self.enable_iptables
          remove_ebtables_chains(vnic) if self.enable_ebtables
        end
        
        def apply_task(task)
          task.rules.each { |rule|
            cmds = []
            if rule.is_a?(EbtablesRule)  && self.enable_ebtables
              cmds << get_rule_command(rule,:apply)
            elsif rule.is_a?(IptablesRule) && self.enable_iptables
              cmds << get_rule_command(rule,:apply)
            end
            cmds.flatten!
            cmds.compact!
            
            puts cmds.join("\n") if self.verbose_commands
          
            system(cmds.join("\n"))
          }
        end
        
        def remove_task(task)
          task.rules.each { |rule|
            cmds = []
            if rule.is_a?(EbtablesRule) && self.enable_ebtables
              cmds << get_rule_command(rule,:remove)
            elsif rule.is_a?(IptablesRule) && self.enable_iptables
              cmds << get_rule_command(rule,:remove)
            end
            cmds.flatten!
            cmds.compact!
            
            puts cmds.join("\n") if self.verbose_commands
          
            system(cmds.join("\n"))
          }
        end
      end
    
    end
  end
end
