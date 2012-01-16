# -*- coding: utf-8 -*-

require 'strscan'
require 'ipaddress'

module Dcmgr::Models
  class SecurityGroupRule < BaseNew

    many_to_one :security_group

    def to_hash
      {
        :permission => permission,
        
      }.merge(self.class.parse_rule(self.permission))
    end


    def validate
      super

      self.class.parse_rule(self.permission)
    end

    def self.parse_rule(rule)
      rule = rule.strip.gsub(/[\s\t]+/, '')
      from_group = false
      
      # ex.
      # "tcp:22,22,ip4:0.0.0.0"
      # "udp:53,53,ip4:0.0.0.0"
      # "icmp:-1,-1,ip4:0.0.0.0"
      
      # 1st phase
      # ip_tport    : tcp,udp? 1 - 16bit, icmp: -1
      # id_port has been separeted in first phase.
      from_pair, ip_tport, source_pair = rule.split(',')
      
      return nil if from_pair.nil? || ip_tport.nil? || source_pair.nil?
      
      # 2nd phase
      # ip_protocol : [ tcp | udp | icmp ]
      # ip_fport    : tcp,udp? 1 - 16bit, icmp: -1
      ip_protocol, ip_fport = from_pair.split(':')
      
      # protocol    : [ ip4 | ip6 | security_group_uuid ]
      # ip_source   : ip4? xxx.xxx.xxx.xxx./[0-32], ip6? (not yet supprted)
      protocol, ip_source = source_pair.split(':')
      
      s = StringScanner.new(protocol)
      until s.eos?
        case
        when s.scan(/ip6/)
          # TODO#FUTURE: support IPv6 address format
          return
        when s.scan(/ip4/)
          # IPAddress doesn't support prefix '0'.
          ip_addr, prefix = ip_source.split('/', 2)
          if prefix.to_i == 0
            ip_source = ip_addr
          end
        when s.scan(/sg-\w+/)
          from_group = true
        else
          raise "Unexpected protocol '#{s.peep(20)}'"
        end
      end
      
      if from_group == false
        #p "from_group:(#{from_group}) ip_source -> #{ip_source}"
        ip = IPAddress(ip_source)
        ip_source = case ip.u32
                    when 0
                      "#{ip.address}/0"
                    else
                      "#{ip.address}/#{ip.prefix}"
                    end
      else
        ip_source = protocol
        protocol = nil
      end
      
      case ip_protocol
      when 'tcp', 'udp'
        ip_fport = ip_fport.to_i
        ip_tport = ip_tport.to_i
        
        # validate port range
        [ ip_fport, ip_tport ].each do |port|
          raise "Out of range port number: #{port}" unless port >= 1 && port <= 65535
        end
        
        if !(ip_fport <= ip_tport)
          raise "Invalid IP port range: #{ip_fport} <= #{ip_tport}"
        end
        
        {
          :ip_protocol => ip_protocol,
          :ip_fport    => ip_fport,
          :ip_tport    => ip_tport,
          :protocol    => protocol,
          :ip_source   => ip_source,
        }
      when 'icmp'
        # via http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/
        #
        # For the ICMP protocol, the ICMP type and code must be specified.
        # This must be specified in the format type:code where both are integers.
        # Type, code, or both can be specified as -1, which is a wildcard.
        
        icmp_type = ip_fport.to_i
        icmp_code = ip_tport.to_i
        
        # icmp_type
        case icmp_type
        when -1
        when 0, 3, 5, 8, 11, 12, 13, 14, 15, 16, 17, 18
        else
          raise "Unsupported ICMP type number: #{icmp_type}"
        end
        
        # icmp_code
        case icmp_code
        when -1
        when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
          # when icmp_type equals -1 icmp_code must equal -1.
          return if icmp_type == -1
        else
          raise "Unsupported ICMP code number: #{icmp_code}"
        end
        
        {
          :ip_protocol => ip_protocol,
          :icmp_type   => ip_tport.to_i, # ip_tport.to_i, # -1 or 0,       3,    5,       8,        11, 12, 13, 14, 15, 16, 17, 18
          :icmp_code   => ip_fport.to_i, # ip_fport.to_i, # -1 or 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
          :protocol    => protocol,
          :ip_source   => ip_source,
        }
      else
        raise "Unsupported protocol: #{ip_protocol}"
      end
    end
    
  end
end
