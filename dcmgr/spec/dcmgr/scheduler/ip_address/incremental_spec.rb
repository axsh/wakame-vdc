# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/incremental_examples/*.rb"].each {|f| require f }

describe Dcmgr::Scheduler::IPAddress::Incremental do
  include NetworkHelper

  describe "#schedule" do
    let(:network_vif) { Fabricate(:network_vif, network: network) }

    describe "sad paths" do
      subject do
        lambda { Dcmgr::Scheduler::IPAddress::Incremental.new.schedule(options) }
      end

      include_examples "fail argument checks"
      include_examples "dhcp range exhausted"
    end

    describe "happy paths" do
      subject do
        Dcmgr::Scheduler::IPAddress::Incremental.new.schedule(options)
        network_vif
      end

      context "when options is a NetworkVif with its network set" do
        let(:network) do
          n = Fabricate(:network, ipv4_network: "192.168.0.0")
          set_dhcp_range(n)
          n
        end
        let(:options) { network_vif }

        it "assigns the first address in the network" do
          expect(subject.direct_ip_lease.first.ipv4).to eq "192.168.0.1"
        end
      end
    end
  end
end
