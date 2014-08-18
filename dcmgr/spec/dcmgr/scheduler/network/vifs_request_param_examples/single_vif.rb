# -*- coding: utf-8 -*-

shared_examples "single vif" do
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
end
