# -*- coding: utf-8 -*-

require 'spec_helper'

describe "Dcmgr::Scheduler::Network::VifsRequestParam" do
  def set_dhcp_range(network)
    nw_ipv4 = IPAddress::IPv4.new("#{network.ipv4_network}/#{network.prefix}")

    Fabricate(:dhcp_range, network: network,
                           range_begin: nw_ipv4.first,
                           range_end: nw_ipv4.last)
  end

  describe "#schedule" do
    subject(:inst) do
      i = Fabricate(:instance, request_params: {"vifs" => vifs_parameter})

      Dcmgr::Scheduler::Network::VifsRequestParam.new.schedule(i)

      i
    end

    let!(:mac_range) { Fabricate(:mac_range) }

    context "with a malformed vifs parameter" do
      let(:vifs_parameter) { "JOSSEFIEN!" }

      it "raises an error" do
        expect { inst }.to raise_error Dcmgr::Scheduler::NetworkSchedulingError
      end
    end

    context "with a single entry in the vifs parameter" do
      let(:network) { Fabricate(:network).tap {|n| set_dhcp_range(n)} }
      let(:vifs_parameter) do
        { "eth0" => {"index" => 0, "network" => network.canonical_uuid } }
      end

      it "schedules a single network interface for the instance" do
        expect(inst.network_vif.size).to eq 1
      end

      it "schedules the interface in the network we specified" do
        expect(inst.network_vif.first.network).to eq network
      end
    end

    context "with a two entries in the vifs parameter and different networks" do
      let(:network1) { Fabricate(:network).tap {|n| set_dhcp_range(n)} }
      let(:network2) { Fabricate(:network).tap {|n| set_dhcp_range(n)} }

      let(:vifs_parameter) do
        eth0 = {"index" => 0, "network" => network1.canonical_uuid }
        eth1 = {"index" => 1, "network" => network2.canonical_uuid }

        { "eth0" => eth0, "eth1" => eth1 }
      end

      it "schedules two network interfaces for the instance" do
        expect(inst.network_vif.size).to eq 2
      end

      it "schedules the first network interface in network1" do
        expect(inst.network_vif.first.network).to eq network1
      end

      it "schedules the first network interface in network2" do
        expect(inst.network_vif.last.network).to eq network2
      end
    end

  end
end
