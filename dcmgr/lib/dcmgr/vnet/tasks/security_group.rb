# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks
    
      class SecurityGroup < Task
        include Dcmgr::VNet::Netfilter
        def initialize(group_map)
          super()
          
          # Parse the rules in case they are referencing other security groups
          parsed_rules = group_map[:rules].map { |rule|
            ref_group_id = rule[:ip_source].scan(/sg-\w+/).first
            if ref_group_id
              referencees = group_map[:referencees][ref_group_id]
              next if referencees.nil?
              
              new_rules = referencees.values.map { |vnic|
                new_rule = rule.dup
                new_rule[:protocol] = "ip4"
                new_rule[:ip_source] = "#{vnic[:address]}/32"
                
                new_rule
              }
              new_rules
            else
              rule
            end
          }.flatten.uniq.compact
          
          parsed_rules.each { |rule|
            case rule[:ip_protocol]
            when 'tcp', 'udp'
              if rule[:ip_fport] == rule[:ip_tport]
                self.rules << IptablesRule.new(:filter,:forward,rule[:ip_protocol].to_sym,:incoming,"-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --dport #{rule[:ip_fport]} -j ACCEPT")
              else
                self.rules << IptablesRule.new(:filter,:forward,rule[:ip_protocol].to_sym,:incoming,"-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --dport #{rule[:ip_fport]}:#{rule[:ip_tport]} -j ACCEPT")
              end
            when 'icmp'
              # icmp
              #   This extension can be used if `--protocol icmp' is specified. It provides the following option:
              #   [!] --icmp-type {type[/code]|typename}
              #     This allows specification of the ICMP type, which can be a numeric ICMP type, type/code pair, or one of the ICMP type names shown by the command
              #      iptables -p icmp -h
              if rule[:icmp_type] == -1 && rule[:icmp_code] == -1
                self.rules << IptablesRule.new(:filter,:forward,rule[:ip_protocol].to_sym,:incoming,"-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} -j ACCEPT")
              else
                self.rules << IptablesRule.new(:filter,:forward,rule[:ip_protocol].to_sym,:incoming,"-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --icmp-type #{rule[:icmp_type]}/#{rule[:icmp_code]} -j ACCEPT")
              end
            end
          }
        end
      end

    end
  end
end
