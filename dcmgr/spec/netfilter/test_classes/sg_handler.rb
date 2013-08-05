# -*- coding: utf-8 -*-

class SGHandlerTest
  include Dcmgr::VNet::SGHandler

  def add_host(hn)
    @hosts ||= {}
    raise "Host already exists: #{hn.canonical_uuid}" if @hosts[hn.canonical_uuid]
    @hosts[hn.canonical_uuid] = NetfilterAgentTest.new
  end

  def get_netfilter_agent(hn)
    @hosts[hn.canonical_uuid]
  end
  alias :nfa :get_netfilter_agent

  def call_packetfilter_service(hn, method, *args)
    @hosts[hn.canonical_uuid].send(method, *args)
  end
end

# some syntax sugar
def nfa(host)
  handler.nfa(host)
end
