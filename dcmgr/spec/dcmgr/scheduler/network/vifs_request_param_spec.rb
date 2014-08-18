# -*- coding: utf-8 -*-

require 'spec_helper'

describe "Dcmgr::Scheduler::Network::VifsRequestParam" do
  describe "#schedule" do
    subject(:inst) do
      Fabricate(:instance, request_params: {"vifs" => vifs_parameter}).tap do |i|
        Dcmgr::Scheduler::Network::VifsRequestParam.new.schedule(i)
      end
    end

    let!(:mac_range) { Fabricate(:mac_range) }
    let(:network) { Fabricate(:network) }

    let!(:dhcp_range) do
      nw_ipv4 = IPAddress::IPv4.new("#{network.ipv4_network}/#{network.prefix}")

      Fabricate(:dhcp_range, network: network,
                             range_begin: nw_ipv4.first,
                             range_end: nw_ipv4.last)
    end

    context "with a malformed vifs parameter" do
      let(:vifs_parameter) { "JOSSEFIEN!" }

      it { is_expected.to raise_error Dcmgr::Scheduler::NetworkSchedulingError }
    end

    context "with a single entry in the vifs parameter" do
      let(:vifs_parameter) do
        { "eth0" => {"index" => 0, "network" => network.canonical_uuid } }
      end

      it "schedules a single network interface for the instance" do
        expect(inst.network_vif.size).to eq 1
        expect(inst.network_vif.first.network).to be network
      end

    end
  end
end
