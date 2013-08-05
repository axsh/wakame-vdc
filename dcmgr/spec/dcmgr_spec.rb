# -*- coding: utf-8 -*-

require 'rubygems'
require 'dcmgr'

module DcmgrSpec
  module Netfilter
    autoload :SGHandlerTest, 'netfilter/test_classes/sg_handler'
    autoload :NFCmdParser, 'netfilter/test_classes/nf_cmd_parser'
    autoload :NetfilterAgentTest, 'netfilter/test_classes/netfilter_agent'
  end
end
