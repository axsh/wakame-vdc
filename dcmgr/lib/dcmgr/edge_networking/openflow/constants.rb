# -*- coding: utf-8 -*-

require 'trema'

module Dcmgr
  module EdgeNetworking
    module OpenFlow

      module OpenFlowConstants
        # Default table used by all incoming packets.
        TABLE_CLASSIFIER = 0

        # Straight-forward routing of packets to the port tied to the
        # destination mac address, which includes all non-virtual
        # networks.
        TABLE_ROUTE_DIRECTLY = 3

        # Routing to non-virtual networks with filtering applied.
        #
        # Due to limitations in the rules we can use the filter rules
        # for the destination must be applied first, and its port number
        # loaded into a registry.
        #
        # The source will then apply filtering rules and output to the
        # port number found in registry 1.
        TABLE_LOAD_DST = 4
        TABLE_LOAD_SRC = 5

        # Routing to virtual networks.
        #
        # Each port participating in a virtual network will load the
        # virtual network id to registry 2 in the classifier table for
        # all types of packets.
        #
        # The current filtering rules are bare-boned and provide just
        # routing.
        TABLE_VIRTUAL_SRC = 6
        TABLE_VIRTUAL_DST = 7

        # The ARP antispoof table ensures no ARP packet SHA or SPA field
        # matches the mac address owned by another port.
        #
        # If valid, the next table routes the packet to the right port.
        TABLE_ARP_ANTISPOOF = 10
        TABLE_ARP_ROUTE = 11

        # Routing to the metadata server.
        #
        # Currently using the OpenFlowController, rather than learning
        # flows.
        TABLE_METADATA_OUTGOING = 12
        TABLE_METADATA_INCOMING = 13

        TABLE_MAC_ROUTE = 14

        # Used by OpenFlowPort to indicate the type of port.
        PORT_TYPE_NONE = 0
        PORT_TYPE_ETH = 1
        PORT_TYPE_TUNNEL = 2
        PORT_TYPE_INSTANCE_NET = 3
        PORT_TYPE_INSTANCE_VNET = 4

        PORT_NUMBER_LOCAL = 65534
        PORT_NUMBER_CONTROLLER = 65535
      end

    end
  end
end
