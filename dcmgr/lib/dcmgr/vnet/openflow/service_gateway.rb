# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceGateway < ServiceBase
    include Dcmgr::Logger

    def install
      remove_flows

      if self.network.virtual and self.of_port
        # Drop source IPs that are part of the destination network to avoid spoofing.
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 6, {:ip => nil, :in_port => self.of_port, :nw_src => "#{self.network.ipv4_network}/#{self.network.prefix}"}, {:drop => nil})
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 5, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac}, {:resubmit => 7})
      end

      flush_flows
    end

  end

end
