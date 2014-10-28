# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Dcmgr::VNet::OpenFlow

  class PacketHandler

    attr_reader :match_blk
    attr_reader :action_blk

    def initialize(match_blk, action_blk)
      @match_blk = match_blk
      @action_blk = action_blk
    end

    def handle(switch, port, message)
      if match_blk.call(switch, port, message)
        action_blk.call(switch, port, message)
      end
    end

  end

end
