# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceGateway < ServiceBase
    include Dcmgr::Logger

    attr_accessor :route_ipv4
    attr_accessor :route_prefix
    attr_accessor :route_mode
    attr_accessor :gateway_type

    def install
      remove_flows

      logger.debug "Installing service gateway flows: type:#{self.gateway_type.inspect} network:#{self.network.id} port:#{self.of_port}"

      if self.of_port.nil? ||
          self.route_ipv4.nil? ||
          self.route_prefix.nil? ||
          (self.route_mode != :inner && self.route_mode != :outer)
        logger.debug "Could not install gateway flows, invalid values detected."
        return
      end

      case self.gateway_type
      when :gateway_openflow then install_gateway_openflow
      when :gateway_instance then install_gateway_instance
      when :nat_openflow     then install_nat_openflow
      when :nat_instance     then install_nat_instance
      else
        logger.info "Unknown gateway_type: #{self.gateway_type.inspect}"
      end

      flush_flows
    end

    def install_gateway_openflow
    end

    def install_gateway_instance
      if self.network.virtual && self.route_mode == :inner
        # Drop source IPs that are part of the destination network to avoid spoofing.
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 6, {:ip => nil, :in_port => self.of_port,
                              :nw_src => "#{self.network.ipv4_network}/#{self.network.prefix}"},
                            {:drop => nil})
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 5, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac},
                            {:resubmit => TABLE_VIRTUAL_DST})

      elsif self.network.virtual && self.route_mode == :outer
        # Nothing needed here.
      elsif !self.network.virtual && self.route_mode == :inner
        queue_flow Flow.new(TABLE_LOAD_SRC, 5, {:ip => nil, :in_port => self.of_port,
                              :nw_src => "#{self.network.ipv4_network}/#{self.network.prefix}"},
                            {:drop => nil})
        queue_flow Flow.new(TABLE_LOAD_SRC, 4, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac},
                            {:output_reg0 => nil})

      elsif !self.network.virtual && self.route_mode == :outer
        queue_flow Flow.new(TABLE_LOAD_DST, 3, {:ip => nil, :dl_dst => self.mac, :nw_dst => "#{self.route_ipv4}/#{self.route_prefix}"},
                            {:load_reg0 => self.of_port, :resubmit => TABLE_LOAD_SRC})
        queue_flow Flow.new(TABLE_LOAD_SRC, 3, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac,
                              :nw_src => "#{self.route_ipv4}/#{self.route_prefix}"},
                            {:output_reg0 => nil})
      end
    end

    def install_nat_openflow
    end

    def install_nat_instance
      if self.network.virtual && self.route_mode == :inner
        # Drop source IPs that are part of the destination network to avoid spoofing.
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 6, {:ip => nil, :in_port => self.of_port,
                              :nw_src => "#{self.network.ipv4_network}/#{self.network.prefix}"},
                            {:drop => nil})
        queue_flow Flow.new(TABLE_VIRTUAL_SRC, 5, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac},
                            {:resubmit => TABLE_VIRTUAL_DST})

      elsif self.network.virtual && self.route_mode == :outer
        # Nothing needed here.
      elsif !self.network.virtual && self.route_mode == :inner
        queue_flow Flow.new(TABLE_LOAD_SRC, 5, {:ip => nil, :in_port => self.of_port,
                              :nw_src => "#{self.network.ipv4_network}/#{self.network.prefix}"},
                            {:drop => nil})
        queue_flow Flow.new(TABLE_LOAD_SRC, 4, {:ip => nil, :in_port => self.of_port, :dl_src => self.mac},
                            {:output_reg0 => nil})

      elsif !self.network.virtual && self.route_mode == :outer
        # Nothing needed here.
      end
    end

  end

end
