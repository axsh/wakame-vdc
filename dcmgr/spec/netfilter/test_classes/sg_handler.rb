# -*- coding: utf-8 -*-

module DcmgrSpec::Netfilter
  class SGHandlerTest
    include Dcmgr::EdgeNetworking::SGHandler
    include Dcmgr::EdgeNetworking::VNicInitializer

    def add_host(hn)
      @hosts ||= {}
      raise "Host already exists: #{hn.canonical_uuid}" if @hosts[hn.canonical_uuid]
      @hosts[hn.canonical_uuid] = NetfilterHandlerTest.new
    end

    def get_netfilter_agent(hn)
      @hosts[hn.canonical_uuid]
    end
    alias :nfa :get_netfilter_agent

    def call_packetfilter_service(hn, cmds)
      @hosts[hn.canonical_uuid].send(:apply_packetfilter_cmds, cmds)
    end
  end

  # some syntax sugar
  def nfa(host)
    handler.nfa(host)
  end
end
