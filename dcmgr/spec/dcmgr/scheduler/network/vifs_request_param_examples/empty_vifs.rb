# -*- coding: utf-8 -*-

shared_examples "empty vifs" do
  context "with an empty vifs parameter" do
    let(:vifs_parameter) { Hash.new }

    it "schedules an instance with no network interfaces" do
      expect(subject.network_vif).to be_empty
    end
  end
end
