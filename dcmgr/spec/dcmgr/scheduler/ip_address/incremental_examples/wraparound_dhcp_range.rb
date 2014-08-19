# -*- coding: utf-8 -*-

shared_examples "wraparound dhcp range" do
  context "when reaching the end of all dhcp ranges while past ip address have been released" do
    let(:network) do
      n = Fabricate(:network, ipv4_network: "192.168.0.0")

      set_dhcp_range(n, "192.168.0.1", "192.168.0.5")
      set_dhcp_range(n, "192.168.0.11", "192.168.0.15")

      n
    end

    before do
      10.times { incremental.schedule Fabricate(:network_vif, network: network) }

      network_vif_from_ip_lease("192.168.0.12").destroy
      network_vif_from_ip_lease("192.168.0.3").destroy
      network_vif_from_ip_lease("192.168.0.5").destroy
    end

    it "assigns the first open ip lease" do
      expect(subject).to eq "192.168.0.3"
    end
  end
end
