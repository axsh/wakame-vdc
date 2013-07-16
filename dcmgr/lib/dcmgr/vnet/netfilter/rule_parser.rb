# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::VNet::Netfilter
  # Parses Wakame-vdc format security group rules
  # and spits out netfilter rules
  def self.parse_rules(sg_rules)
    sg_rules.map { |rule|
      begin
        ipv4_rule_src = IPAddress::IPv4.new(rule[:ip_source])
        if ipv4_rule_src.to_u32 == 0
          # Do not set 0.0.0.0 to --arp-ip-*. it seems not to
          # understand as any match.

          #TODO: Figure out a way to do this without requiring the vnic address
          # chain.add_rule "--protocol arp --arp-opcode Request --arp-ip-dst #{@vnic[:address]} -j ACCEPT"
        else
          "--protocol arp --arp-opcode Request --arp-ip-src #{rule[:ip_source]} --arp-ip-dst #{@vnic[:address]} -j ACCEPT"
        end
      rescue ArgumentError => e
        STDERR.puts e
      end

      case rule[:ip_protocol]
      when 'tcp', 'udp'
        if rule[:ip_fport] == rule[:ip_tport]
          "-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --dport #{rule[:ip_fport]} -j ACCEPT"
        else
          "-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --dport #{rule[:ip_fport]}:#{rule[:ip_tport]} -j ACCEPT"
        end
      when 'icmp'
        # icmp
        #   This extension can be used if `--protocol icmp' is specified. It provides the following option:
        #   [!] --icmp-type {type[/code]|typename}
        #     This allows specification of the ICMP type, which can be a numeric ICMP type, type/code pair, or one of the ICMP type names shown by the command
        #      iptables -p icmp -h
        if rule[:icmp_type] == -1 && rule[:icmp_code] == -1
          "-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} -j ACCEPT"
        else
          "-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --icmp-type #{rule[:icmp_type]}/#{rule[:icmp_code]} -j ACCEPT"
        end
      end
    }
  end
end
