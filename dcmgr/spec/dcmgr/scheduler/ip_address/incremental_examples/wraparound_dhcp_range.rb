# -*- coding: utf-8 -*-

shared_examples "wraparound dhcp range" do
  context "when reaching the end of all dhcp ranges while past ip addresses have been released" do
    let(:network) do
      Fabricate(:network, ipv4_network: "192.168.0.0").tap do |n|
        set_dhcp_range(n, "192.168.0.1", "192.168.0.5")
        set_dhcp_range(n, "192.168.0.11", "192.168.0.15")
      end
    end

    before do
      10.times { incremental.schedule Fabricate(:network_vif, network: network) }

      network_vif_from_ip_lease("192.168.0.12").destroy
      network_vif_from_ip_lease("192.168.0.3").destroy
      network_vif_from_ip_lease("192.168.0.5").destroy
    end

    create_and_schedule_vif = proc do
      n = Fabricate(:network_vif, network: network)

      incremental.schedule(n)

      n.direct_ip_lease.first.ipv4
    end

    let(:vnic2_ipv4, &create_and_schedule_vif)
    let(:vnic3_ipv4, &create_and_schedule_vif)

    it "assigns the released ip addresses in incremental order" do
      expect(vnic2_ipv4).to eq "192.168.0.3"
      expect(vnic3_ipv4).to eq "192.168.0.5"
      expect(subject).to eq "192.168.0.12"
    end
  end
end
