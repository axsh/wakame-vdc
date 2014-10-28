# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Drops all ARP packets coming into the host
      class DropArpToHost < Task
        include Dcmgr::VNet::Netfilter
        attr_reader :enable_logging
        attr_reader :log_prefix

        def initialize
          super()

          # Drop forwarding to host
          #self.rules << EbtablesRule.new(:filter,:input,:arp,:outgoing,"--log-level 4 --log-ip --log-arp --log-prefix '#{self.log_prefix}' -j CONTINUE") if self.enable_logging
          self.rules << EbtablesRule.new(:filter,:input,:arp,:outgoing,"#{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        end
      end

    end
  end
end
