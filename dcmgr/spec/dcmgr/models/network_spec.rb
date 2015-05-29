require_relative "helper"

describe Dcmgr::Models::Network do
  context "#add_ipv4_dynamic_range" do
    let(:network) {      Fabricate(:network, ipv4_network: "192.168.0.0") }

    it "works" do
      n = network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end
  end
end
