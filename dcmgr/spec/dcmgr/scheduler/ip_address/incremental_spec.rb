# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/incremental_examples/*.rb"].each {|f| require f }

describe Dcmgr::Scheduler::IPAddress::Incremental do
  include NetworkHelper

  describe "#schedule" do
    let(:network_vif) { Fabricate(:network_vif, network: network) }
    let(:incremental) { Dcmgr::Scheduler::IPAddress::Incremental.new }

    describe "sad paths" do
      subject { lambda { incremental.schedule(options) } }

      include_examples "fail argument checks"
      include_examples "dhcp range exhausted"
    end

    describe "happy paths" do
      subject do
        incremental.schedule(network_vif)

        network_vif.direct_ip_lease.first.ipv4
      end

      include_examples "first ip in range"
      include_examples "one range full, one empty"
      include_examples "gateway in dhcp range"
      include_examples "wraparound dhcp range"
    end
  end
end
