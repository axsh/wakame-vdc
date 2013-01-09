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

      @services = []
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

    def get_service(name, vif_uuid = nil)
      name_sym = name.to_sym

      self.services.detect { |service|
        service.name == name_sym && (vif_uuid.nil? || service.vif_uuid == vif_uuid)
      }
    end

    def find_services(name)
      name_sym = name.to_sym

      self.services.select { |service|
        service.name == name_sym
      }
    end

    def add_service(switch, service_map)
      if get_service(service_map[:name], service_map[:network_vif_uuid])
        logger.info "Duplicate service: name:'#{name}'."
        return
      end

      port = switch.find_vif_id(service_map[:network_vif_uuid])

      args = {
        :switch => switch,
        :network => self,
        :name => service_map[:name].to_sym,
        :vif_uuid => service_map[:network_vif_uuid],
        :mac => service_map[:mac_addr],
        :ip => IPAddr.new(service_map[:address]),
        :of_port => port ? port.port_info.number : nil,
      }

      case args[:name]
      when :dhcp
        logger.info "Adding DHCP service."
        service = ServiceDhcp.new(args)
      when :dns
        logger.info "Adding DNS service."
        service = ServiceDns.new(args)
      when :gateway
        logger.info "Adding GATEWAY service."
        service = ServiceGateway.new(args)
      when :metadata
        logger.info "Adding METADATA service."
        service = ServiceMetadata.new(args.merge!({:of_port => service_map[:port], :listen_port => service_map[:incoming_port]}))
      else
        logger.info "Unknown service name, not creating: '#{service_map[:name]}'."
        return
      end

      self.services << service
      service.install

      if virtual && service.ip && service.mac && service_map[:instance_uuid].nil?
        arp_handler.add(service.mac, service.ip, service)
        icmp_handler.add(service.mac, service.ip, service)
      end
    end
    
    def update_service_port(switch, service_map, port)
      service = get_service(service_map[:name], service_map[:network_vif_uuid])

      return if service.vif_uuid.empty? || service.nil?

      service.of_port = port.port_info.number
      service.install
    end

    def delete_service(switch, service_map)
      name_sym = service_map[:name].to_sym
      vif_uuid = service_map[:network_vif_uuid]

      deleted_services = self.services.delete_if { |service|
        service.name == name_sym && (vif_uuid.nil? || service.vif_uuid == vif_uuid)
      }

      if deleted_services.empty?
        logger.info "No such service: name:'#{service_map[:name]}'."
        return
      end

      logger.info "Deleting service: name:'#{service_map[:name]}'."

      deleted_services.each { |service| service.uninstall }

      # Remove arp/icmp handlers if required.
    end

    def update_route_port(switch, route_map, port)
      # Clear the related flows in this case.
      return unless route_map[:inner_nw] and route_map[:outer_nw]

      find_services(:gateway).each { |service|
        if route_map[:inner_vif][:network_vif_uuid] == port.port_info.name
          service.route_ipv4 = route_map[:outer_nw][:ipv4]
          service.route_prefix = route_map[:outer_nw][:prefix]
        elsif route_map[:outer_vif][:network_vif_uuid] == port.port_info.name
          service.route_ipv4 = route_map[:inner_nw][:ipv4]
          service.route_prefix = route_map[:inner_nw][:prefix]
        else
          next
        end

        logger.info "Updating route port: inner_nw:#{route_map[:inner_vif][:network_vif_uuid]} outer_nw:#{route_map[:outer_vif][:network_vif_uuid]}."

        service.of_port = port.port_info.number
        service.install
      }
    end

  end
end
