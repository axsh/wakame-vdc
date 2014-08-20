# -*- coding: utf-8 -*-

shared_examples "gateway in dhcp range" do
  context "with a default gateway set in the dhcp range" do
    context "as the first address" do
      let(:network) do
        n = Fabricate(:network, ipv4_network: "192.168.0.0",
                                ipv4_gw: "192.168.0.1")

        set_dhcp_range(n, "192.168.0.1", "192.168.0.5")

        n
      end

      it "is skipped when scheduling ip addresses for vnics" do
        expect(subject).to eq "192.168.0.2"
      end
    end

    context "in the middle of the range" do
      let(:network) do
        n = Fabricate(:network, ipv4_network: "192.168.0.0",
                                ipv4_gw: "192.168.0.3")

        set_dhcp_range(n, "192.168.0.1", "192.168.0.5")

        n
      end

      before do
        2.times { incremental.schedule Fabricate(:network_vif, network: network) }
      end

      it "is skipped when scheduling ip addresses for vnics" do
        expect(subject).to eq "192.168.0.4"
      end
    end
  end
end
