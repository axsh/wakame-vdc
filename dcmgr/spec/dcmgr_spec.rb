# -*- coding: utf-8 -*-

require 'rubygems'
require 'dcmgr'
require 'spec_helper'

module DcmgrSpec
  module Netfilter
    autoload :SGHandlerTest, 'netfilter/test_classes/sg_handler'
    autoload :NFCmdParser, 'netfilter/test_classes/nf_cmd_parser'
    autoload :NetfilterHandlerTest, 'netfilter/test_classes/netfilter_handler'

    module Matchers
      require "netfilter/matchers/have_applied_vnic"
      require "netfilter/matchers/have_applied_secg"
      require "netfilter/matchers/have_nothing_applied"
      autoload :ChainMethods, "netfilter/matchers/chain_methods"
    end
  end

  module Fabricators
    require 'fabrication'

    TEST_ACCOUNT ||= "a-shpoolxx"
    require "fabricators/host_node"
    require "fabricators/instance"
    require "fabricators/vnic"
    require "fabricators/network"
    require "fabricators/secg"
  end
end
