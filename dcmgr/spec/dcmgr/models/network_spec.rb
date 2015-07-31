require_relative "helper"

describe Dcmgr::Models::Network do
  let(:network) { Fabricate(:network, ipv4_network: "192.168.0.0") }

  context "#add_ipv4_dynamic_range" do
    it "works" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end

    it "works with only one address" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.1")
    end

    it "works with non-existing ranges" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.11", "192.168.0.20")
      network.add_ipv4_dynamic_range("192.168.0.30", "192.168.0.40")
    end

    it "fails with IPs out of network" do
      expect {
        network.add_ipv4_dynamic_range("172.16.0.1", "172.16.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("192.168.0.1", "172.16.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("172.16.0.1", "192.168.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("192.168.0.0", "192.168.0.255")
      }.to raise_error Sequel::ValidationFailed
    end

    it "fails with left high and right low range" do
      expect {
        network.add_ipv4_dynamic_range("192.168.0.10", "192.168.0.1")
      }.to raise_error RuntimeError
    end

    it "fails to add overwrap range" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      expect {
        network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.1")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("192.168.0.10", "192.168.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("192.168.0.5", "192.168.0.20")
      }.to raise_error RuntimeError
    end
  end

  context "#del_ipv4_dynamic_range" do
    before do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end

    it "works" do
      network.del_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end

    it "works with only one address" do
      network.add_ipv4_dynamic_range("192.168.0.100", "192.168.0.100")
      network.del_ipv4_dynamic_range("192.168.0.100", "192.168.0.100")
    end

    it "fails with non-existing range" do
      expect {
        network.del_ipv4_dynamic_range("192.168.0.100", "192.168.0.110")
      }.to raise_error RuntimeError
    end

    it "fails with left high and right low range" do
      expect {
        network.del_ipv4_dynamic_range("192.168.0.10", "192.168.0.1")
      }.to raise_error RuntimeError
    end

    it "fails with IPs out of network" do
      expect {
        network.del_ipv4_dynamic_range("172.16.0.1", "172.16.0.10")
      }.to raise_error RuntimeError
      expect {
        network.del_ipv4_dynamic_range("192.168.0.1", "172.16.0.10")
      }.to raise_error RuntimeError
      expect {
        network.del_ipv4_dynamic_range("172.16.0.1", "192.168.0.10")
      }.to raise_error RuntimeError
    end

    it "fails with partial matching range" do
      expect {
        network.del_ipv4_dynamic_range("192.168.0.1", "192.168.0.5")
      }.to raise_error RuntimeError
      expect {
        network.del_ipv4_dynamic_range("192.168.0.5", "192.168.0.20")
      }.to raise_error RuntimeError
    end
  end
end
