# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceDns < ServiceBase
    include Dcmgr::Logger

    attr_accessor :domain_name

    def install(network)
    end

  end
  
end
