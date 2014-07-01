# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Allows for DHCP traffic to take place with and only with wakame's DHCP server
      class AcceptWakameDHCPOnly < Task
        include Dcmgr::VNet::Netfilter
        #TODO: allow ARP traffic to DHCP server
        attr_reader :dhcp_server_ip

        def initialize(dhcp_server_ip,fport = 67, tport = 68)
          super()

          @dhcp_server_ip = dhcp_server_ip

          # Block DHCP replies that aren't coming from our DHCP server
          self.rules << IptablesRule.new(:filter,:forward,:udp,:incoming,"-p udp ! -s #{self.dhcp_server_ip} --sport #{fport}:#{tport} -j DROP")

          # Accept DHCP replies coming from our DHCP server
          self.rules << IptablesRule.new(:filter,:forward,:udp,:incoming,"-p udp -s #{self.dhcp_server_ip} --sport #{fport}:#{tport} -j ACCEPT")
        end
      end

    end
  end
end
