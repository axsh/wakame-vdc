# -*- coding: utf-8 -*-

shared_examples "dhcp range exhausted" do
  context "with a network whose dhcp range is exhausted" do
    let(:network) { Fabricate(:network) }
    let(:options) { network_vif }

    it { is_expected.to raise_error Dcmgr::Models::OutOfIpRange }
  end
end

