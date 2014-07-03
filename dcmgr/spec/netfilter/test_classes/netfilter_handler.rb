# -*- coding: utf-8 -*-

module DcmgrSpec::Netfilter
  class NetfilterHandlerTest
    include Dcmgr::EdgeNetworking::Netfilter::NetfilterHandler

    def initialize(*args)
      super *args
      @parser = NFCmdParser.new
      # self.verbose_netfilter = true
    end

    def method_missing(method, *args)
      @parser.send(method, *args)
    end

    private
    def apply_packetfilter_cmds(cmds)
      def system(cmd)
        @parser.parse(cmd.split("\n"))
      end

      super
    end
  end
end
