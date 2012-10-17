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

      module CustomChains
        #************************
        #Iptables part
        #************************
        class DVnicIpChain < IptablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter, "d_#{@vnic[:uuid]}")
          end

          def jumps
            [IptablesRule.new(:filter,:forward,nil,nil,"-m physdev --physdev-is-bridged --physdev-out #{@vnic[:uuid]} -j #{@name}")]
          end

          def tailor!(rule)
            return rule
          end
        end

        class SVnicIpChain < IptablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter, "s_#{@vnic[:uuid]}")
          end

          def jumps
            [IptablesRule.new(:filter,:forward,nil,nil,"-m physdev --physdev-is-bridged --physdev-in #{@vnic[:uuid]} -j #{@name}")]
          end

          def tailor!(rule)
            return rule
          end
        end

        class VnicIpChainTCP < IptablesChain
          BOUNDS = {:incoming => "d", :outgoing => "s"}

          def initialize(bound,vnic)
            raise ArgumentError, "Invalid bound: #{bound}. Valid bounds are #{BOUNDS.keys.join(",")}" unless BOUNDS.keys.member?(bound) unless BOUNDS.keys.member?(bound)
            @bound = bound
            @vnic = vnic
            super(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}_tcp")
          end

          def jumps
            jumps = []

            if @bound == :incoming
              jumps << IptablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",:tcp,:outgoing,"-m state --state NEW,ESTABLISHED -p tcp -j #{@name}")
            elsif @bound == :outgoing
              jumps << IptablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",:tcp,:incoming,"-p tcp -j #{@name}")
            end

            jumps
          end

          def tailor!(rule)
            if rule.is_a?(IptablesRule) && rule.table == :filter && rule.chain == "FORWARD" && rule.protocol == :tcp && rule.bound == @bound
              rule.chain = @name
            end

            rule
          end

        end

        class VnicIpChainUDP < IptablesChain
          BOUNDS = {:incoming => "d", :outgoing => "s"}

          def initialize(bound,vnic)
            raise ArgumentError, "Invalid bound: #{bound}. Valid bounds are #{BOUNDS.keys.join(",")}" unless BOUNDS.keys.member?(bound)
            @bound = bound
            @vnic = vnic
            super(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}_udp")
          end

          def jumps
            jumps = []

            if @bound == :incoming
              jumps << IptablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",:udp,:outgoing,"-m state --state NEW,ESTABLISHED -p udp -j #{@name}")
            elsif @bound == :outgoing
              jumps << IptablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",:udp,:incoming,"-p udp -j #{@name}")
            end

            jumps
          end

          def tailor!(rule)
            if rule.is_a?(IptablesRule) && rule.table == :filter && rule.chain == "FORWARD" && rule.protocol == :udp && rule.bound == @bound
              rule.chain = @name
            end

            rule
          end

        end

        class VnicIpChainICMP < IptablesChain
          BOUNDS = {:incoming => "d", :outgoing => "s"}

          def initialize(bound,vnic)
            raise ArgumentError, "Invalid bound: #{bound}. Valid bounds are #{BOUNDS.keys.join(",")}" unless BOUNDS.keys.member?(bound)
            @bound = bound
            @vnic = vnic
            super(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}_icmp")
          end

          def jumps
            jumps = []

            if @bound == :incoming
              jumps << IptablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",:udp,:outgoing,"-m state --state NEW,ESTABLISHED,RELATED -p icmp -j #{@name}")
            elsif @bound == :outgoing
              jumps << IptablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",:udp,:incoming,"-p icmp -j #{@name}")
            end

            jumps
          end

          def tailor!(rule)
            if rule.is_a?(IptablesRule) && rule.table == :filter && rule.chain == "FORWARD" && rule.protocol == :icmp && rule.bound == @bound
              rule.chain = @name
            end

            rule
          end

        end

        class VnicIpSnatExceptions < IptablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:nat,"#{@vnic[:uuid]}_snat_exceptions")
          end

          def jumps
            [IptablesRule.new(:nat,:postrouting,nil,nil,"-s #{@vnic[:address]} -j #{@name}")]
          end

          def tailor!(rule)
            # Very hackish but should work for now
            if rule.table == :nat && rule.chain == "POSTROUTING" && (not (rule.rule.include? "-j SNAT"))
              rule.chain = @name
            end

            rule
          end
        end

        class VnicIpSnat < IptablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:nat,"#{@vnic[:uuid]}_snat")
          end

          def jumps
            [IptablesRule.new(:nat,:postrouting,nil,nil,"-s #{@vnic[:address]} -j #{@name}")]
          end

          def tailor!(rule)
            # Very hackish but should work for now
            if rule.table == :nat && rule.chain == "POSTROUTING" && rule.rule.include?("-j SNAT")
              rule.chain = @name
            end

            rule
          end
        end

        #************************
        #Ebtables part
        #************************
        class SVnicEbChain < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter, "s_#{@vnic[:uuid]}")
          end

          def jumps
            [EbtablesRule.new(:filter,:forward,nil,nil,"-i #{@vnic[:uuid]} -j #{@name}")]
          end

          def tailor!(rule)
            return rule
          end
        end

        class DVnicEbChain < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter, "d_#{@vnic[:uuid]}")
          end

          def jumps
            [EbtablesRule.new(:filter,:forward,nil,nil,"-o #{@vnic[:uuid]} -j #{@name}")]
          end

          def tailor!(rule)
            return rule
          end
        end

        class VnicEbChainARP < EbtablesChain
          BOUNDS = {:incoming => "d", :outgoing => "s"}

          def initialize(bound,vnic)
            raise ArgumentError, "Invalid bound: #{bound}. Valid bounds are #{BOUNDS.keys.join(",")}" unless BOUNDS.keys.member?(bound)
            @bound = bound
            @vnic = vnic
            super(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}_arp")
          end

          def jumps
            [EbtablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",nil,:outgoing,"-p arp -j #{@name}")]
          end

          def tailor!(rule)
            if rule.is_a?(EbtablesRule) && rule.table == :filter && rule.chain == "FORWARD" && rule.bound == @bound && rule.protocol == :arp
            rule.chain = @name
            end
            rule
          end
        end

        class VnicEbChainIPV4 < EbtablesChain
          BOUNDS = {:incoming => "d", :outgoing => "s"}

          def initialize(bound,vnic)
            raise ArgumentError, "Invalid bound: #{bound}. Valid bounds are #{BOUNDS.keys.join(",")}" unless BOUNDS.keys.member?(bound)
            @bound = bound
            @vnic = vnic
            super(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}_ipv4")
          end

          def jumps
            [EbtablesRule.new(:filter,"#{BOUNDS[@bound]}_#{@vnic[:uuid]}",nil,:outgoing,"-p IPv4 -j #{@name}")]
          end

          def tailor!(rule)
            if rule.is_a?(EbtablesRule) && rule.table == :filter && rule.chain == "FORWARD" && rule.bound == @bound && rule.protocol == :ip4
              rule.chain = @name
            end

            rule
          end
        end

        class VnicEbChainToHost < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter,"s_#{@vnic[:uuid]}_d_host")
          end

          def jumps
            [EbtablesRule.new(:filter,:input,nil,:outgoing,"-i #{@vnic[:uuid]} -j #{@name}")]
          end

          def tailor!(rule)
            rule
          end
        end

        class VnicEbChainFromHost < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter,"d_#{@vnic[:uuid]}_s_host")
          end

          def jumps
            [EbtablesRule.new(:filter,:output,nil,:outgoing,"-o #{@vnic[:uuid]} -j #{@name}")]
          end

          def tailor!(rule)
            rule
          end
        end

        class VnicEbChainToHostARP < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter,"s_#{@vnic[:uuid]}_d_host_arp")
          end

          def jumps
              [EbtablesRule.new(:filter,"s_#{@vnic[:uuid]}_d_host",nil,:outgoing,"-p arp -j #{@name}")]
          end

          def tailor!(rule)
            if rule.is_a?(EbtablesRule) && rule.table == :filter && rule.chain == "INPUT" && rule.protocol == :arp
              rule.chain = @name
            end

            rule
          end
        end

        class VnicEbChainFromHostARP < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter,"d_#{@vnic[:uuid]}_s_host_arp")
          end

          def jumps
              [EbtablesRule.new(:filter,"d_#{@vnic[:uuid]}_s_host",nil,:incoming,"-p arp -j #{@name}")]
          end

          def tailor!(rule)
            if rule.is_a?(EbtablesRule) && rule.table == :filter && rule.chain == "OUTPUT" && rule.protocol == :arp
              rule.chain = @name
            end

            rule
          end
        end

        class VnicEbChainToHostIPV4 < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter,"s_#{@vnic[:uuid]}_d_host_ipv4")
          end

          def jumps
              [EbtablesRule.new(:filter,"s_#{@vnic[:uuid]}_d_host",nil,:outgoing,"-p IPv4 -j #{@name}")]
          end

          def tailor!(rule)
            if rule.is_a?(EbtablesRule) && rule.table == :filter && rule.chain == "INPUT" && rule.protocol == :ip4
              rule.chain = @name
            end

            rule
          end
        end

        class VnicEbChainFromHostIPV4 < EbtablesChain
          def initialize(vnic)
            @vnic = vnic
            super(:filter,"d_#{@vnic[:uuid]}_s_host_ipv4")
          end

          def jumps
              [EbtablesRule.new(:filter,"d_#{@vnic[:uuid]}_s_host",nil,:incoming,"-p IPv4 -j #{@name}")]
          end

          def tailor!(rule)
            if rule.is_a?(EbtablesRule) && rule.table == :filter && rule.chain == "INPUT" && rule.protocol == :ip4
              rule.chain = @name
            end

            rule
          end
        end
      end

      class VNicProtocolTaskManager < NetfilterTaskManager
        include CustomChains

        # These are flags that decide whether or not iptables and ebtables are enabled
        attr_accessor :enable_iptables
        attr_accessor :enable_ebtables
        # Flag that decides whether or not we output commands that are applied
        attr_accessor :verbose_commands
        # If defined, this script will be executed every time netfilter rules are updated
        attr_accessor :netfilter_hook_script_path

        def initialize
          super
        end

        def apply_vnic_chains(vnic_map)
          commands = []
          if self.enable_iptables
            # Create all iptables chains
            iptables_chains(vnic_map).each { |chain|
              commands << "iptables -t #{chain.table} -N #{chain.name}"
              chain.jumps.each { |jump|
                commands << get_rule_command(jump,:apply)
              }
            }
          end

          if self.enable_ebtables
            ebtables_chains(vnic_map).each { |chain|
              commands << "ebtables -t #{chain.table} -N #{chain.name}"
              commands << "ebtables -t #{chain.table} -P #{chain.name} RETURN"
              chain.jumps.each { |jump|
                commands << get_rule_command(jump,:apply)
              }
            }
          end

          execute_commands(commands.flatten.uniq)
        end

        def remove_vnic_chains(vnic_map)
          commands = []
          if self.enable_iptables
            # Remove all jumps to this vnic's chains
            ip_chains = iptables_chains(vnic_map)
            ip_chains.each { |chain|
              chain.jumps.each { |jump|
                commands << get_rule_command(jump,:remove)
              }
            }

            # Remove this vnic's chains
            ip_chains.each { |chain|
              commands << "iptables -t #{chain.table} -F #{chain.name}"
              commands << "iptables -t #{chain.table} -X #{chain.name}"
            }
          end

          if self.enable_ebtables
            # Remove all jumps to this vnic's chains
            eb_chains = ebtables_chains(vnic_map)
            eb_chains.each { |chain|
              chain.jumps.each { |jump|
                commands << get_rule_command(jump,:remove)
              }
            }

            # Remove this vnic's chains
            eb_chains.each { |chain|
              commands << "ebtables -t #{chain.table} -F #{chain.name}"
              commands << "ebtables -t #{chain.table} -X #{chain.name}"
            }
          end

          execute_commands(commands.flatten.uniq)
        end

        def handle_vnic_tasks(vnic,tasks,action)
          commands = []

          tasks.each { |task|
            next unless task.is_a? Task
            task.rules.each { |rule|
              if self.enable_iptables && rule.is_a?(IptablesRule)
                # If a rule is protocol independent, copy it for each protocol
                if rule.protocol.nil? && rule.table == :filter
                  IptablesRule.protocols.each { |k,v|
                    new_rule = rule.dup
                    new_rule.protocol = v.to_sym
                    # Determine which custom chain a rule is intended for
                    iptables_chains(vnic).each { |chain|
                      chain.tailor!(new_rule)
                    }
                    commands << get_rule_command(new_rule,action)
                  }
                else
                  # Determine which custom chain a rule is intended for
                  iptables_chains(vnic).each { |chain|
                    chain.tailor!(rule)
                  }
                  commands << get_rule_command(rule,action)
                end
              elsif self.enable_ebtables && rule.is_a?(EbtablesRule)
                # Determine which custom chain a rule is intended for
                ebtables_chains(vnic).each { |chain|
                  chain.tailor!(rule)
                }
                commands << get_rule_command(rule,action)
              end
            }
          }

          execute_commands(commands.flatten.uniq)
        end

        def apply_vnic_tasks(vnic,tasks)
          handle_vnic_tasks(vnic,tasks,:apply)
        end

        def remove_vnic_tasks(vnic,tasks)
          handle_vnic_tasks(vnic,tasks,:remove)
        end

        def execute_commands(cmds)
          puts cmds.join("\n") if self.verbose_commands
          system(cmds.join("\n"))
          system(self.netfilter_hook_script_path) unless self.netfilter_hook_script_path.nil?
        end

        #def execute_commands_debug(cmds)
          #cmds.each { |cmd|
            #puts cmd
            #system(cmd)
          #}
        #end
        #alias :execute_commands :execute_commands_debug

        # Translates _rule_ into a command that can be directly passed on to the OS
        # _action_ determines if the command must _:apply_ or _:remove_ a rule.
        def get_rule_command(rule,action)
          actions = {:apply => "I", :remove => "D"}
          raise ArgumentError, "#{rule} is not a valic rule" unless rule.is_a?(IptablesRule) || rule.is_a?(EbtablesRule)
          raise ArgumentError, "action must be one of the following: '#{actions.keys.join(",")}'" unless actions.member? action

          if rule.is_a?(IptablesRule) && self.enable_iptables
            "iptables -t #{rule.table} -#{actions[action]} #{rule.chain} #{rule.rule}"
          elsif rule.is_a?(EbtablesRule) && self.enable_ebtables
            "ebtables -t #{rule.table} -#{actions[action]} #{rule.chain} #{rule.rule}"
          else
            nil
          end
        end

        # Creates all returns the custom chains used for iptables
        def iptables_chains(vnic_map)
          chains = []

          chains << DVnicIpChain.new(vnic_map)
          chains << SVnicIpChain.new(vnic_map)
          [:incoming,:outgoing].each { |bound|
            chains << VnicIpChainTCP.new(bound,vnic_map)
            chains << VnicIpChainUDP.new(bound,vnic_map)
            chains << VnicIpChainICMP.new(bound,vnic_map)
          }
          chains << VnicIpSnat.new(vnic_map)
          chains << VnicIpSnatExceptions.new(vnic_map)

          chains
        end

        # Creates and returns all the custom chains used for ebtables
        def ebtables_chains(vnic_map)
          chains = []

          chains << SVnicEbChain.new(vnic_map)
          chains << DVnicEbChain.new(vnic_map)
          [:incoming,:outgoing].each { |bound|
            chains << VnicEbChainARP.new(bound,vnic_map)
            chains << VnicEbChainIPV4.new(bound,vnic_map)
          }
          chains << VnicEbChainFromHost.new(vnic_map)
          chains << VnicEbChainFromHostARP.new(vnic_map)
          chains << VnicEbChainFromHostIPV4.new(vnic_map)

          chains << VnicEbChainToHost.new(vnic_map)
          chains << VnicEbChainToHostARP.new(vnic_map)
          chains << VnicEbChainToHostIPV4.new(vnic_map)

          chains
        end

        def apply_tasks(tasks)
          commands = []

          commands = tasks.map { |task|
            next unless task.is_a? Task
            task.rules.map { |rule|
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
      end

    end
  end
end
