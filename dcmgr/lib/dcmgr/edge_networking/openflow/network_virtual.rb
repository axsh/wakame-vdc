# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class NetworkVirtual < OpenFlowNetwork
    include Dcmgr::Logger

    def initialize dp, id
      super(dp, id)
    end

    def virtual
      true
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

  end

end
