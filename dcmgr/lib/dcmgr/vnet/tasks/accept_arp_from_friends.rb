# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Explicitely allows ARP traffic between "friend" nics
      class AcceptARPFromFriends < Task
        include Dcmgr::VNet::Netfilter
        attr_reader :inst_ip
        attr_reader :friend_ips
        attr_reader :enable_logging
        attr_reader :log_prefix

        def initialize(inst_ip,friend_ips,enable_logging,log_prefix)
          super()

          @enable_logging = enable_logging
          @log_prefix = log_prefix
          @inst_ip = inst_ip
          @friend_ips = friend_ips

          friend_ips.each { |friend_ip|
            # Log traffic
            self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Request --arp-ip-src #{friend_ip} --arp-ip-dst #{self.inst_ip} --log-ip --log-arp --log-prefix '#{self.log_prefix}'       -j CONTINUE") if self.enable_logging
            self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Request --arp-ip-src #{friend_ip} --arp-ip-dst #{self.inst_ip} -j ACCEPT")
          }
        end
      end

    end
  end
end
