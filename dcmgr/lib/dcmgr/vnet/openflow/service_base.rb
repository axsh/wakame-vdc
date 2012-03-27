# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceBase
    include OpenFlowConstants

    attr_reader :switch
    attr_accessor :of_port

    attr_accessor :mac
    attr_accessor :ip
    attr_accessor :listen_port
    
    def initialize(args = {})
      @switch = args[:switch]
      @of_port = args[:of_port]

      @mac = args[:mac]
      @ip = args[:ip]
      @listen_port = args[:listen_port]
    end

  end
end
