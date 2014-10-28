# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceBase
    include Dcmgr::Logger
    include OpenFlowConstants
    include FlowGroup

    attr_reader :switch
    attr_reader :network
    attr_accessor :of_port

    attr_accessor :mac
    attr_accessor :ip
    attr_accessor :listen_port

    def initialize(args = {})
      @switch = args[:switch]
      @network = args[:network]
      @of_port = args[:of_port]

      @mac = args[:mac]
      @ip = args[:ip]
      @listen_port = args[:listen_port]
    end

    def datapath
      network.datapath
    end

    def uninstall
      remove_flows
    end

  end

end
