# -*- coding: utf-8 -*-

require 'rubygems'
require 'dcmgr'

module DcmgrSpec
  module Netfilter
    autoload :SGHandlerTest, 'netfilter/test_classes/sg_handler'
    autoload :NFCmdParser, 'netfilter/test_classes/nf_cmd_parser'
    autoload :NetfilterAgentTest, 'netfilter/test_classes/netfilter_agent'

    module Matchers
      require "netfilter/matchers/have_applied_vnic"
      require "netfilter/matchers/have_applied_secg"
      require "netfilter/matchers/have_nothing_applied"
      autoload :ChainMethods, "netfilter/matchers/chain_methods"
    end
  end
end
