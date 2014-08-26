# -*- coding: utf-8 -*-

shared_examples "two vifs" do
  context "with two entries in the vifs parameter and different networks" do
    let(:network1) { Fabricate(:network).tap {|n| set_dhcp_range(n)} }
    let(:network2) { Fabricate(:network).tap {|n| set_dhcp_range(n)} }

    let(:vifs_parameter) do
      eth0 = {"index" => 0, "network" => network1.canonical_uuid }
      eth1 = {"index" => 1, "network" => network2.canonical_uuid }

      { "eth0" => eth0, "eth1" => eth1 }
    end

    it "schedules two network interfaces for the instance" do
      expect(subject.network_vif.size).to eq 2
    end

    it "schedules the first network interface in network1" do
      expect(subject.network_vif.first.network).to eq network1
    end

    it "schedules the first network interface in network2" do
      expect(subject.network_vif.last.network).to eq network2
    end
  end
end
