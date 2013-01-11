# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      class TranslateLoggingAddress < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :host_ip
        attr_accessor :logging_ip
        attr_accessor :logging_port

        ACCEPT_PROTOCOLS = [:udp, :tcp].freeze

        def initialize(vnic_id, host_ip, logging_ip, logging_port)
          super()

          self.host_ip = host_ip
          self.logging_ip = logging_ip
          self.logging_port = logging_port

          ACCEPT_PROTOCOLS.each do |protocol|
            self.rules << IptablesRule.new(:nat,:prerouting,nil,:incoming,"-m physdev --physdev-in #{vnic_id} -d #{self.logging_ip} -p #{protocol} --dport #{logging_port} -j DNAT --to-destination #{self.host_ip}:#{self.logging_port}")
            self.rules << IptablesRule.new(:filter,:forward,protocol,:outgoing,"-p #{protocol} -d #{self.host_ip} --dport #{self.logging_port} -j ACCEPT")
          end
        end
      end

    end
  end
end
