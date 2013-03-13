# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'
require 'ipaddress'

module Dcmgr
  module Rpc
    class NatBoxHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      job :foo do
      end

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
