# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/incremental_examples/*.rb"].each {|f| require f }

describe Dcmgr::Scheduler::IPAddress::Incremental do
  include NetworkHelper

  describe "#schedule" do
    subject { network_vif }

    let(:network_vif) { Fabricate(:network_vif, network: network) }

    describe "sad paths" do
      subject do
        lambda { Dcmgr::Scheduler::IPAddress::Incremental.new.schedule(options) }
      end

      include_examples "fail argument checks"
      include_examples "dhcp range exhausted"
    end
  end
end
