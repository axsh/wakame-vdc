# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'
require 'ipaddress'

module Dcmgr
  module Rpc
    class NatboxHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
