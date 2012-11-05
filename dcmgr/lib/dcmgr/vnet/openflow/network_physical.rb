# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class NetworkPhysical < OpenFlowNetwork
    include Dcmgr::Logger

    def initialize dp, id
      super(dp, id, false)

      self.class.eth_ports[datapath.datapath_id] ||= []
    end

    def self.eth_ports
      @eth_ports ||= {}
    end

    def self.add_eth_port(datapath_id, port)
      switch_ports = (self.eth_ports[datapath_id] ||= [])
      switch_ports.count(port) == 0 ? switch_ports << port : nil
    end

    def self.physical_flood_flows(datapath_id)
      @physical_flood_flows ||= {}
      @physical_flood_flows[datapath_id] ||=
        [ Flow.new(TABLE_MAC_ROUTE,      1,
                   {:dl_dst => 'FF:FF:FF:FF:FF:FF'},
                   {:local => nil, :for_each => [self.eth_ports[datapath_id], {:output => :placeholder}]}),
          Flow.new(TABLE_ROUTE_DIRECTLY, 1,
                   {:dl_dst => 'FF:FF:FF:FF:FF:FF'},
                   {:local => nil, :for_each => [self.eth_ports[datapath_id], {:output => :placeholder}]}),
          Flow.new(TABLE_LOAD_DST,       1,
                   {:dl_dst => 'FF:FF:FF:FF:FF:FF'},
                   {:load_reg0 => PORT_NUMBER_LOCAL, :resubmit => TABLE_LOAD_SRC, :for_each => [self.eth_ports[datapath_id], {:load_reg0 => :placeholder, :resubmit => TABLE_LOAD_SRC}]}),
          Flow.new(TABLE_ARP_ROUTE,      1,
                   {:arp => nil, :dl_dst => 'FF:FF:FF:FF:FF:FF', :arp_tha => '00:00:00:00:00:00'},
                   {:local => nil, :for_each => [self.eth_ports[datapath_id], {:output => :placeholder}]}),
        ]
    end

    def update
      self.datapath.add_flows(self.flood_flows)
      self.datapath.add_flows(self.class.physical_flood_flows(self.datapath.datapath_id))
    end

    def remove_port port
      super.remove_port(port)
      self.eth_ports[datapath.datapath_id].delete(port)
    end

  end

end
