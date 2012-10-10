# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      class AcceptARPFromDNS < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :dns_server_ip

        def initialize(dns_server_ip,enable_logging = false,log_prefix = "A arp from_dns: ")
          super()
          self.dns_server_ip = dns_server_ip
          # Allow broadcast from the gateway
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-ip-src=#{self.dns_server_ip} #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT")
        end
      end

    end
  end
end
