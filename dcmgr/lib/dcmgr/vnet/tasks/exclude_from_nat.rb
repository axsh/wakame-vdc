# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Contains specific rules for ip addresses to which connections should
      # not be natted.
      class ExcludeFromNat < Task
        include Dcmgr::VNet::Netfilter
        #An array of the ip addresses excluded from nat
        attr_accessor :excluded_ips

        def initialize(ips,self_ip)
          super()
          raise ArgumentError, "ips Must be an array containing IP addresses" unless ips.is_a? Array

          ips.each { |ip|
            if ip.is_a? String
              exclude = IPAddress(ip)
            elsif ip.is_a? IPAddress
              exclude = ip
            else
              next
            end

            #self.rules << IptablesRule.new(:nat,:prerouting,nil,:incoming,"-d #{self_ip} -s #{ip} -j ACCEPT")
            self.rules << IptablesRule.new(:nat,:postrouting,nil,:outgoing,"-d #{ip} -s #{self_ip} -j ACCEPT")
          }
        end
      end

      # Contains specific rules for ip addresses to which connections should
      # not be natted. Depends on the netfilter IpSet module
      class ExcludeFromNatIpSet < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :excluded_ips

        def initialize(ips,self_ip)
          raise NotImplementedError
        end
        #TODO: Write this class!
      end

    end
  end
end
