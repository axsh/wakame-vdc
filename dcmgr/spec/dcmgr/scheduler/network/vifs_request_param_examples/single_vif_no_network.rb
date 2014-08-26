# -*- coding: utf-8 -*-

shared_examples "single vif no network" do
  context "with a single entry with no network in the vifs parameter" do
    let(:vifs_parameter) do
      { "eth0" => {"index" => 0 } }
    end

    it "schedules a single network interface for the instance" do
      expect(subject.network_vif.size).to eq 1
    end

    it "doesn't schedule a network for the interface" do
      expect(subject.network_vif.first.network).to be nil
    end
  end
end
