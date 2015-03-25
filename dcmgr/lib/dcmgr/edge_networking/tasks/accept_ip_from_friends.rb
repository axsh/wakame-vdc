# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # Explicitely allows IP traffic between "friend" nics
      class AcceptIpFromFriends < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_reader :friend_ips

        def initialize(friend_ips)
          super()

          @friend_ips = friend_ips

          friend_ips.each { |friend_ip|
            self.rules << IptablesRule.new(:filter,:forward,nil,:incoming,"-s #{friend_ip} -j ACCEPT")
          }
        end
      end

    end
  end
end
