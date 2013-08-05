# -*- coding: utf-8 -*-

module DcmgrSpec::Netfilter
  class NetfilterAgentTest
    include Dcmgr::VNet::Netfilter::NetfilterAgent

    def initialize(*args)
      super *args
      @parser = NFCmdParser.new
    end

    def method_missing(method, *args)
      @parser.send(method, *args)
    end

    private
    def exec(cmds)
      cmds = [cmds] unless cmds.is_a?(Array)
      @parser.parse(cmds)
    end
  end
end
