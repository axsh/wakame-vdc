# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      class TranslateMetadataAddress < Task
        include Dcmgr::VNet::Netfilter
        #TODO: allow ARP traffic to metadata server
        attr_reader :metadata_ip
        attr_reader :metadata_port
        attr_reader :metadata_fake_ip
        attr_reader :metadata_fake_port

        def initialize(vnic_id,metadata_ip,metadata_port,metadata_fake_ip = "169.254.169.254",metadata_fake_port = "80")
          super()

          @metadata_ip = metadata_ip
          @metadata_port = metadata_port
          @metadata_fake_ip = metadata_fake_ip
          @metadata_fake_port = metadata_fake_port

          # Translate requests to the metadata server
          self.rules << IptablesRule.new(:nat,:prerouting,:tcp,:outgoing,"-m physdev --physdev-in #{vnic_id} -d #{self.metadata_fake_ip} -p tcp --dport #{self.metadata_fake_port} -j DNAT --to-destination #{self.metadata_ip}:#{self.metadata_port}")
          # Accept tcp traffic to the metadata server
          self.rules << IptablesRule.new(:filter,:forward,:tcp,:outgoing,"-p tcp -d #{self.metadata_ip} --dport #{self.metadata_port} -j ACCEPT")
        end
      end

    end
  end
end
