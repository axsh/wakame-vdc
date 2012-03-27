# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceBase
    include OpenFlowConstants

    attr_reader :switch
    attr_reader :of_port

    attr_reader :mac
    attr_reader :ip
    attr_reader :listen_port
    
    def initialize(args = {})
      @switch = args[:switch]
      @of_port = args[:of_port]

      @mac = args[:mac]
      @ip = args[:ip]
      @listen_port = args[:listen_port]
    end

  end
end
