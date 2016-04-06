# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # Explicitely allows ARP traffic to take place from the instance to the host
      class AcceptARPToHost < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_reader :enable_logging
        attr_reader :log_prefix
        attr_reader :host_ip
        attr_reader :inst_ip

        def initialize(host_ip,inst_ip,enable_logging,log_prefix)
          super()

          @enable_logging = enable_logging
          @log_prefix = log_prefix
          @host_ip = host_ip
          @inst_ip = inst_ip

          self.rules << EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-ip-src #{self.inst_ip} --arp-ip-dst #{self.host_ip} --log-ip --log-arp --log-prefix '#{self.log_prefix}' -j CONTINUE") if self.enable_logging
          self.rules << EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-ip-src #{self.inst_ip} -j ACCEPT")
        end
      end

    end
  end
end
