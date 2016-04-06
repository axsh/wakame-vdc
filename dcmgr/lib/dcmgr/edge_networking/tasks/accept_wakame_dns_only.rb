# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # Allows for DNS traffic to be exchanged with and only with Wakame's DNS server
      class AcceptWakameDNSOnly < Task
        include Dcmgr::EdgeNetworking::Netfilter
        #TODO: allow ARP traffic to DNS server
        attr_reader :dns_server_ip
        attr_reader :dns_server_port

        def initialize(dns_server_ip,dns_server_port="53")
          super()

          @dns_server_ip = dns_server_ip
          @dns_server_port = dns_server_port

          # Allow DNS traffic to take place
          self.rules << IptablesRule.new(:filter,:forward,:udp,:outgoing,"-p udp -d #{self.dns_server_ip} --dport #{self.dns_server_port} -j ACCEPT")
          self.rules << IptablesRule.new(:filter,:forward,:udp,:incoming,"-p udp -d #{self.dns_server_ip} --dport #{self.dns_server_port} -j ACCEPT")

          # Disable any non DNS traffic to DNS server
          #[:udp,:tcp,:icmp].each { |protocol|
            #self.rules << IptablesRule.new(:filter,:forward,protocol,:outgoing,"-d #{self.dns_server_ip} -p #{protocol} -j DROP")
          #}
        end
      end

    end
  end
end
