# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # Drops all ARP packet forwarding
      class DropArpForwarding < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_reader :enable_logging
        attr_reader :log_prefix

        def initialize(enable_logging,log_prefix)
          super()

          @enable_logging = enable_logging
          @log_prefix = log_prefix

          # Drop forwarding to other instances
          #self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--log-level 4 --log-ip --log-arp --log-prefix 'D d_#{self.log_prefix}_arp:' -j CONTINUE") if self.enable_logging
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"#{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        end
      end

    end
  end
end
