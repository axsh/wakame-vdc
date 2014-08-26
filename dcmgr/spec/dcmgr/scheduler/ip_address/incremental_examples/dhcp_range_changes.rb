# -*- coding: utf-8 -*-

shared_examples 'dhcp range changes' do
  context "when dhcp range changes" do
    let(:network) do
      Fabricate(:network, ipv4_network: "192.168.0.0").tap do |n|
        set_dhcp_range(n, "192.168.0.10", "192.168.0.15")
      end
    end

    before do
      3.times do
        incremental.schedule Fabricate(:network_vif, network: network)
      end

      destroy_dhcp_range(network, "192.168.0.10", "192.168.0.15")

      set_dhcp_range(network, "192.168.0.4", "192.168.0.6")
    end

    it "assigns the lowest available address in the new range" do
      expect(subject).to eq "192.168.0.4"
    end
  end
end
