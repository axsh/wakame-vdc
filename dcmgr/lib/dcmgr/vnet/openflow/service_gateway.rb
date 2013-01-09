# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceGateway < ServiceBase
    include Dcmgr::Logger

    attr_accessor :route_ipv4
    attr_accessor :route_prefix

    def install
      remove_flows

      return unless self.of_port

      # return if no route/something.

      install_gateway_instance

      flush_flows
    end

    def install_gateway_instance
      if self.network.virtual
        # Drop source IPs that are part of the destination network to avoid spoofing.
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 6, {:ip => nil, :in_port => self.of_port,
                              :nw_src => "#{self.network.ipv4_network}/#{self.network.prefix}"}, {:drop => nil})
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 5, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac}, {:resubmit => 7})
      else
        return unless self.route_ipv4 and self.route_prefix

        queue_flow Flow.new(TABLE_LOAD_DST, 3, {
                              :ip => nil,
                              :dl_dst => self.mac,
                              :nw_dst => "#{self.route_ipv4}/#{self.route_prefix}"
                            }, {
                              :load_reg0 => self.of_port,
                              :resubmit => 5
                            })
        queue_flow Flow.new(TABLE_LOAD_SRC, 3, {
                              :ip => nil,
                              :in_port => self.of_port,
                              :dl_src => self.mac,
                              :nw_src => "#{self.route_ipv4}/#{self.route_prefix}"
                            }, {
                              :output_reg0 => nil
                            })
      end
    end

  end

end
