# -*- coding: utf-8 -*-

module Dcmgr::Cli::Debug

  class Base < Dcmgr::Cli::Base
    protected

    def rpc
      @@rpc
    end

    def self.set_rpc(rpc_object)
      @@rpc = rpc_object
    end

    def broadcast
      @@broadcast
    end

    def self.set_broadcast(channel)
      @@broadcast = channel
    end

  end
end
