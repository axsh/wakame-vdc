# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class OpenFlowNetwork
    include Dcmgr::Logger
    include OpenFlowConstants

    attr_reader :id
    attr_reader :datapath
    attr_reader :virtual

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

    def initialize dp, id, virtual
      @id = id
      @datapath = dp
      @virtual = !!virtual

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

      self.class.eth_ports[datapath.datapath_id] ||= []
    end

    def self.eth_ports
      @eth_ports ||= {}
    end

    def self.add_eth_port(datapath_id, port)
      switch_ports = (self.eth_ports[datapath_id] ||= [])
      switch_ports.count(port) == 0 ? switch_ports << port : nil
    end

    def flood_flows
      @flood_flows ||= Array.new
    end

    def self.physical_flood_flows(datapath_id)
      @physical_flood_flows ||= {}
      @physical_flood_flows[datapath_id] ||=
        [ Flow.new(TABLE_MAC_ROUTE,      1, {:dl_dst => 'FF:FF:FF:FF:FF:FF'}, :for_each => [self.eth_ports[datapath_id], {:output => :placeholder}]),
          Flow.new(TABLE_ROUTE_DIRECTLY, 1, {:dl_dst => 'FF:FF:FF:FF:FF:FF'}, :for_each => [self.eth_ports[datapath_id], {:output => :placeholder}]),
          Flow.new(TABLE_LOAD_DST,       1, {:dl_dst => 'FF:FF:FF:FF:FF:FF'}, :for_each => [self.eth_ports[datapath_id], {:load_reg0 => :placeholder, :resubmit => TABLE_LOAD_SRC}]),
          Flow.new(TABLE_ARP_ROUTE,      1, {:arp => nil, :dl_dst => 'FF:FF:FF:FF:FF:FF', :arp_tha => '00:00:00:00:00:00'}, :for_each => [self.eth_ports[datapath_id], {:output => :placeholder}]),
        ]
    end

    def update
      self.datapath.add_flows(self.flood_flows)
      self.datapath.add_flows(self.class.physical_flood_flows(self.datapath.datapath_id)) if !self.virtual
    end

    def add_port port, is_local
      ports << port
      local_ports << port if is_local
    end

    def remove_port port
      ports.delete port
      local_ports.delete port
      self.eth_ports[datapath.datapath_id].delete port
    end

    def install_virtual_network(eth_port)
      flood_flows << Flow.new(TABLE_VIRTUAL_DST, 0, {:reg1 => id, :dl_dst => 'ff:ff:ff:ff:ff:ff'}, :for_each => [local_ports, {:output => :placeholder}])
      flood_flows << Flow.new(TABLE_VIRTUAL_DST, 1,
                              {:reg1 => id, :reg2 => 0, :dl_dst => 'ff:ff:ff:ff:ff:ff'},
                              {:for_each => [ports, {:output => :placeholder}], :for_each2 => [subnet_macs, {:mod_dl_dst => :placeholder, :output => eth_port}]})

      learn_arp_match = "priority=#{1},idle_timeout=#{3600*10},table=#{TABLE_VIRTUAL_DST},reg1=#{id},reg2=#{0},NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]"
      learn_arp_actions = "output:NXM_NX_REG2[]"

      flows = []

      # Pass packets to the dst table if it originates from an instance on this host. (reg2 == 0)
      flows << Flow.new(TABLE_VIRTUAL_SRC, 8, {:arp => nil, :reg1 => id, :reg2 => 0}, {:drop => nil})
      flows << Flow.new(TABLE_VIRTUAL_SRC, 4, {:reg1 => id, :reg2 => 0}, {:drop => nil})
      # If from an external host, learn the ARP for future use.
      flows << Flow.new(TABLE_VIRTUAL_SRC, 2, {:reg1 => id, :arp => nil}, [{:learn => "#{learn_arp_match},#{learn_arp_actions}"}, {:resubmit => TABLE_VIRTUAL_DST}])
      # Default action is to pass the packet to the dst table.
      flows << Flow.new(TABLE_VIRTUAL_SRC, 0, {:reg1 => id}, {:resubmit => TABLE_VIRTUAL_DST})

      datapath.add_flows flows
    end

    def add_gre_tunnel name, remote_ip
      ovs_ofctl = datapath.ovs_ofctl
      tunnel_name = "t-#{name}-#{id}"

      command = "#{ovs_ofctl.ovs_vsctl} add-port #{ovs_ofctl.switch_name} #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{remote_ip} options:key=#{id}"

      logger.info "Adding GRE tunnel: '#{command}'."
      system(command)
    end

    def install_mac_subnet eth_port, broadcast_addr
      logger.info "Installing mac subnet: broadcast_addr:#{broadcast_addr}."

      flows = []
      flows << Flow.new(TABLE_CLASSIFIER, 7, {:dl_dst => broadcast_addr}, {:drop => nil })
      flows << Flow.new(TABLE_VIRTUAL_SRC, 10, {:dl_dst => broadcast_addr}, {:drop => nil })

      flood_flows << Flow.new(TABLE_CLASSIFIER, 8, {:in_port => eth_port, :dl_dst => broadcast_addr}, {:mod_dl_dst => 'ff:ff:ff:ff:ff:ff', :load_reg1 => id, :load_reg2 => eth_port, :resubmit => TABLE_VIRTUAL_SRC})

      datapath.add_flows flows
    end

    def external_mac_subnet broadcast_addr
      logger.info "Adding external mac subnet: broadcast_addr:#{broadcast_addr}."

      subnet_macs << broadcast_addr

      flows = []
      flows << Flow.new(TABLE_CLASSIFIER, 7, {:dl_dst => broadcast_addr}, {:drop => nil })
      flows << Flow.new(TABLE_VIRTUAL_SRC, 10, {:dl_dst => broadcast_addr}, {:drop => nil })

      datapath.add_flows flows
    end

    def add_service(switch, service_map)
      # Need to search using constant.
      if self.services.has_key? service_map[:name]
        logger.info "Duplicate service: name:'#{service_map[:name]}'."
      end

      args = {
        :switch => switch,
        :network => self,
        :mac => service_map[:mac_addr],
        :ip => IPAddr.new(service_map[:address]),
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

  end
end
