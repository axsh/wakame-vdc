# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      class StaticNatLog < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_accessor :inside_ip
        attr_accessor :outside_ip
        attr_accessor :snat_log_prefix
        attr_accessor :dnat_log_prefix

        def initialize(inside_ip,outside_ip,snat_log_prefix = "",dnat_log_prefix = "")
          super()

          self.inside_ip = inside_ip
          self.outside_ip = outside_ip
          self.snat_log_prefix = snat_log_prefix
          self.dnat_log_prefix = dnat_log_prefix

          self.rules = []
          self.rules << IptablesRule.new(:nat,:prerouting,nil,:incoming,"-d #{self.outside_ip} -j LOG --log-prefix '#{self.dnat_log_prefix}'")
          self.rules << IptablesRule.new(:nat,:postrouting,nil,:outgoing,"-s #{self.inside_ip} -j LOG --log-prefix '#{self.snat_log_prefix}'")
        end
      end

      class StaticNat < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_accessor :inside_ip
        attr_accessor :outside_ip
        attr_accessor :mac_address

        def initialize(inside_ip, outside_ip, mac_address)
          super()

          self.inside_ip = inside_ip
          self.outside_ip = outside_ip
          self.mac_address = mac_address

          self.rules = []

          # Reply ARP requests for the outside ip
          self.rules << EbtablesRule.new(:nat,:prerouting,:arp,:incoming,"-p arp --arp-ip-dst #{self.outside_ip} --arp-opcode REQUEST -j arpreply --arpreply-mac #{self.mac_address}")

          # Translate the ip
          self.rules << IptablesRule.new(:nat,:postrouting,nil,:outgoing,"-s #{self.inside_ip} -j SNAT --to #{self.outside_ip}")
          self.rules << IptablesRule.new(:nat,:prerouting,nil,:incoming,"-d #{self.outside_ip} -j DNAT --to #{self.inside_ip}")
        end
      end

    end
  end
end
