# -*- coding: utf-8 -*-

shared_examples "first ip in range" do
  context "when options is a NetworkVif with its network set" do
    let(:network) do
      n = Fabricate(:network, ipv4_network: "192.168.0.0")
      set_dhcp_range(n)
      n
    end

    it "assigns the first address in the network" do
      expect(subject.direct_ip_lease.first.ipv4).to eq "192.168.0.1"
    end
  end
end
