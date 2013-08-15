# -*- coding: utf-8 -*-

module Dcmgr::VNet::SGHandlerCommon
  def self.included klass
    klass.class_eval do
      include Dcmgr::Logger
    end
  end

  def call_packetfilter_service(host_node, method, *args)
    raise NotImplementedError,  "Classes that include the sg handler module must define a 'call_packetfilter_service(host_node, method, *args)' method"
  end

  private
  def pf
    @pf ||= Dcmgr::VNet.packetfilter_service
  end

  def commit_changes
    pf.pending_changes.each { |host, cmds|
      call_packetfilter_service(host, cmds)
    }
    pf.flush_pending_changes

    nil # Return nil so nothing weird is returned over RPC calls
  end
end
