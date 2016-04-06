# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr
  module EdgeNetworking
    module Tasks

      class SecurityGroup < Task
        include Dcmgr::EdgeNetworking::Netfilter
        def initialize(vnic, group_map)
          super()

          @vnic = vnic

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
            begin
              ipv4_rule_src = IPAddress::IPv4.new(rule[:ip_source])
              if ipv4_rule_src.to_u32 == 0
                # Do not set 0.0.0.0 to --arp-ip-*. it seems not to
                # understand as any match.
                self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Request --arp-ip-dst #{@vnic[:address]} -j ACCEPT")
              else
                self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Request --arp-ip-src #{rule[:ip_source]} --arp-ip-dst #{@vnic[:address]} -j ACCEPT")
              end
            rescue ArgumentError => e
              STDERR.puts e
            end

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
