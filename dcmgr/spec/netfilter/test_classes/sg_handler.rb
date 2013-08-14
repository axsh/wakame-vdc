# -*- coding: utf-8 -*-

module DcmgrSpec::Netfilter
  class SGHandlerTest
    include Dcmgr::VNet::SGHandler
    include Dcmgr::VNet::VNicInitializer

    def add_host(hn)
      @hosts ||= {}
      raise "Host already exists: #{hn.canonical_uuid}" if @hosts[hn.canonical_uuid]
      @hosts[hn.canonical_uuid] = NetfilterHandlerTest.new
    end

    def get_netfilter_agent(hn)
      @hosts[hn.canonical_uuid]
    end
    alias :nfa :get_netfilter_agent

    def call(hn, cmds)
      @hosts[hn.canonical_uuid].send(:apply_packetfilter_cmds, cmds)
    end

    def pf
      @pf ||= Dcmgr::VNet.packetfilter_service.tap { |n|
        n.host_caller = self
      }
    end
  end

  # some syntax sugar
  def nfa(host)
    handler.nfa(host)
  end
end
