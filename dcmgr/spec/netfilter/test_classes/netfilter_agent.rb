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
      def system(cmd)
        @parser.parse(cmd.split("\n"))
      end

      super
    end
  end
end
