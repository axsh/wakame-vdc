# -*- coding: utf-8 -*-

shared_examples "wrong network" do
  context "with a vifs parameter containing a network that doesn't exist" do
    let(:vifs_parameter) do
      { "eth0" => {"index" => 0, "network" => "i_don't_exist" } }
    end

    subject { lambda {inst} }

    it { is_expected.to raise_error Dcmgr::Models::InvalidUUIDError }
  end
end
