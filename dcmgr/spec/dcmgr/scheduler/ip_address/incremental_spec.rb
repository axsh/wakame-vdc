# -*- coding: utf-8 -*-

require 'spec_helper'

describe Dcmgr::Scheduler::IPAddress::Incremental do
  include NetworkHelper

  describe "#schedule" do
    subject { network_vif }

    let(:network) { Fabricate(:network).tap {|n| set_dhcp_range(n)} }
    let(:network_vif) { Fabricate(:network_vif, network: network) }

    describe "sad paths" do
      subject do
        lambda { Dcmgr::Scheduler::IPAddress::Incremental.new.schedule(options) }
      end

      context "when options is not a Hash nor a NetworkVif" do
        let(:options) { "BURN!" }

        it { is_expected.to raise_error ArgumentError }
      end
    end
  end
end
