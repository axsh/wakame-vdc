# -*- coding: utf-8 -*-

shared_examples "dhcp range exhausted" do
  context "with a single entry with a network whose dhcp range is exhausted" do
    let(:network) { Fabricate(:network) }

    let(:vifs_parameter) do
      { "eth0" => {"index" => 0, "network" => network.canonical_uuid } }
    end

    it { is_expected.to raise_error Dcmgr::Models::OutOfIpRange }
  end
end
