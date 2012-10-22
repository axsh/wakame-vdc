# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Explicitely allows IP traffic between the gateway and the instances
      class AcceptIpFromGateway < Task
        include Dcmgr::VNet::Netfilter
        attr_reader :gateway_ip

        def initialize(gateway_ip)
          super()

          @gateway_ip = gateway_ip

          self.rules << IptablesRule.new(:filter,:forward,nil,:incoming,"-s #{gateway_ip} -j ACCEPT")
        end
      end

    end
  end
end
