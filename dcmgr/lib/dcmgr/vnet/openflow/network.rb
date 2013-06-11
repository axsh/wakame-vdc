# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class OpenFlowNetwork
    include Dcmgr::Logger
    include OpenFlowConstants

    attr_reader :id
    attr_reader :datapath

    # Add _numbers postfix.
    attr_reader :ports
    attr_reader :local_ports

    attr_reader :subnet_macs

    attr_accessor :local_hw
    attr_accessor :ipv4_network
    attr_accessor :prefix

    attr_reader :services
    attr_reader :arp_handler
    attr_reader :icmp_handler
    attr_accessor :packet_handlers

    def initialize dp, id
      @id = id
      @datapath = dp

      @ports = []
      @local_ports = []
      @subnet_macs = []

      @prefix = 0

      @services = {}
      @packet_handlers = []

      @arp_handler = ArpHandler.new
      @icmp_handler = IcmpHandler.new
      arp_handler.install(self)
      icmp_handler.install(self)
    end

    def flood_flows
      @flood_flows ||= Array.new
    end

    def update
      self.datapath.add_flows(self.flood_flows)
    end

    def add_port port, is_local
      ports << port
      local_ports << port if is_local
    end

    def remove_port port
      ports.delete port
      local_ports.delete port
    end

    def add_gre_tunnel name, remote_ip
      ovs_ofctl = datapath.ovs_ofctl
      tunnel_name = "t-#{name}-#{id}"

      command = "#{ovs_ofctl.ovs_vsctl} --may-exist add-port #{ovs_ofctl.switch_name} #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{remote_ip} options:key=#{id}"

      logger.info "Adding GRE tunnel: '#{command}'."
      system(command)
    end

    def add_service(switch, service_map)
      # Need to search using constant.
      if self.services.has_key?(service_map[:name].to_sym)
        logger.info "Duplicate service: name:'#{service_map[:name]}'."
        return
      end

      args = {
        :switch => switch,
        :network => self,
        :mac => service_map[:mac_addr],
        :ip => service_map[:address] ? IPAddr.new(service_map[:address]) : nil,
      }

      case service_map[:name]
      when 'dhcp'
        logger.info "Adding DHCP service."
        name = :dhcp
        service = ServiceDhcp.new(args)
      when 'dns'
        logger.info "Adding DNS service."
        name = :dns
        service = ServiceDns.new(args)
      when 'gateway'
        logger.info "Adding GATEWAY service."
        name = :gateway
        service = ServiceGateway.new(args)
      when 'external-ip'
        logger.info "Adding EXTERNAL-IP service."
        name = :external_ip
        service = ServiceGateway.new(args.merge!({:route_type => :external_ip}))
      when 'metadata'
        logger.info "Adding METADATA service."
        name = :metadata
        service = ServiceMetadata.new(args.merge!({:of_port => service_map[:port], :listen_port => service_map[:incoming_port]}))
      else
        logger.info "Unknown service name, not creating: '#{service_map[:name]}'."
        return
      end

      self.services[name] = service
      service.install

      if virtual && service.ip && service.mac && service_map[:instance_uuid].nil?
        arp_handler.add(service.mac, service.ip, service)
        icmp_handler.add(service.mac, service.ip, service)
      end
    end
    
    def delete_service(switch, service_map)
      service = self.services.delete(service_map[:name].to_sym)

      if service.nil?
        logger.info "No such service: name:'#{service_map[:name]}'."
        return
      end

      logger.info "Deleting service: name:'#{service_map[:name]}'."

      service.uninstall

      # Remove arp/icmp handlers if required.
    end

  end
end
