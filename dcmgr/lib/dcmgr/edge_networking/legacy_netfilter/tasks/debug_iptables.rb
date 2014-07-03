# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # via http://backreference.org/2010/06/11/iptables-debugging/
      # To debug ipv4 packets.
      # $ sudo tail -F /var/log/kern.log | grep TRACE:
      class DebugIptables < Task
        include Dcmgr::EdgeNetworking::Netfilter
        def initialize
          super()
          self.rules << IptablesRule.new(:raw,:output,:icmp,:outgoing,"-p icmp -j TRACE")
          self.rules << IptablesRule.new(:raw,:prerouting,:icmp,:incoming,"-p icmp -j TRACE")
        end
      end

    end
  end
end
