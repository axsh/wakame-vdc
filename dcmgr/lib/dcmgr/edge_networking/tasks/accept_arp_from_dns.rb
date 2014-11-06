# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      class AcceptARPFromDNS < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_accessor :dns_server_ip

        def initialize(dns_server_ip,ip,enable_logging = false,log_prefix = "A arp from_dns: ")
          super()
          self.dns_server_ip = dns_server_ip
          # Allow broadcast from the gateway
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Request --arp-ip-src=#{self.dns_server_ip} --arp-ip-dst=#{ip} #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT")
        end
      end

    end
  end
end
