# -*- coding: utf-8 -*-

shared_examples "one range full, one empty" do
  context "when one dhcp range is exhausted but the next one is empty" do
    let(:network) do
      n = Fabricate(:network, ipv4_network: "192.168.0.0")

      set_dhcp_range(n, "192.168.0.3", "192.168.0.5")
      set_dhcp_range(n, "192.168.0.10", "192.168.0.12")

      n
    end

    before do
      3.times { incremental.schedule Fabricate(:network_vif, network: network) }
    end

    it "assigns the first available address in the empty range" do
      expect(subject).to eq "192.168.0.10"
    end
  end
end
