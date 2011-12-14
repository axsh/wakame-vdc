# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks
    
      class SecurityGroup < Task
        include Dcmgr::VNet::Netfilter
        def initialize(group_map)
          super()
          group_map[:rules].each { |rule|
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
