require_relative "helper"
require "ipaddress"

describe Dcmgr::Models::Network do
  let(:network) { Fabricate(:network) }

  context "#add_ipv4_dynamic_range" do
    it "works" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end

    it "fails with IPs out of range" do
      expect {
        network.add_ipv4_dynamic_range("172.16.0.1", "172.16.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("192.168.0.1", "172.16.0.10")
      }.to raise_error RuntimeError
      expect {
        network.add_ipv4_dynamic_range("172.16.0.1", "192.168.0.10")
      }.to raise_error RuntimeError
    end

    #TODO: it "fails with left high and right low range"
  end
  context "#del_ipv4_dynamic_range" do
    before do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end
    
    it "works" do
      network.del_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
    end

    it "fails with IPs out of range" do
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

    #TODO: it "fails with left high and right low range"
  end
  context "#dhcp_range association" do
    it "returns expected type" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      range = network.dhcp_range.first
      expect(range.range_begin).to be_a(IPAddress::IPv4)
      expect(range.range_end).to be_a(IPAddress::IPv4)
    end
  end
  

  context "combined [add|del]_ipv4_dynamic_range" do
    it "add two sparse ranges" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.100", "192.168.0.110")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.1"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.10"
      expect(ranges[1].range_begin.to_s).to eq "192.168.0.100"
      expect(ranges[1].range_end.to_s).to eq "192.168.0.110"
    end

    it "add adjacent ranges to tail" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.11", "192.168.0.20")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges.size).to eq 2
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.1"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.10"
      expect(ranges[1].range_begin.to_s).to eq "192.168.0.11"
      expect(ranges[1].range_end.to_s).to eq "192.168.0.20"
    end

    it "removes single range" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.del_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")

      expect(
             network.dhcp_range_dataset.order(Sequel.asc(:id)).empty?
             ).to be_truthy
    end

    it "removes two sparse ranges" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.20", "192.168.0.30")
      network.del_ipv4_dynamic_range("192.168.0.1", "192.168.0.30")

      expect(
             network.dhcp_range_dataset.order(Sequel.asc(:id)).empty?
             ).to be_truthy
    end

    it "expands head: 0.10-0.20 => 0.5-0.20" do
      network.add_ipv4_dynamic_range("192.168.0.10", "192.168.0.20")
      network.add_ipv4_dynamic_range("192.168.0.5", "192.168.0.10")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges.size).to eq 1
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.5"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.20"
    end

    it "expands tail: 0.1-0.10 => 0.1-0.20" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.9", "192.168.0.20")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges.size).to eq 1
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.1"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.20"
    end

    it "merges two sparse ranges (tail & head): 0.1-0.10, 0.20-0.30 => 0.1-0.30" do
      # Add two sparse ranges
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.20", "192.168.0.30")
      # Add range unites two separate ranges.
      network.add_ipv4_dynamic_range("192.168.0.10", "192.168.0.20")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges.size).to eq 1
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.1"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.30"
    end

    it "merge two sparse ranges (head & tail): 0.5-0.10, 0.15-0.20 => 0.5-0.20" do
      # Add two sparse ranges
      network.add_ipv4_dynamic_range("192.168.0.5", "192.168.0.10")
      network.add_ipv4_dynamic_range("192.168.0.15", "192.168.0.20")
      # Add range covers two above ranges.
      network.add_ipv4_dynamic_range("192.168.0.5", "192.168.0.20")
      
      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges.size).to eq 1
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.5"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.20"
    end

    it "shrinks a range (head): 0.1-0.10 => 0.3-0.10" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.del_ipv4_dynamic_range("192.168.0.1", "192.168.0.3")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.3"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.10"
    end
    
    it "shrinks a range (tail): 0.1-0.10 => 0.1-0.7" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.del_ipv4_dynamic_range("192.168.0.8", "192.168.0.10")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.1"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.7"
    end

    it "splits into ranges: 0.1-0.10 => 0.1-0.3, 0.7-0.10" do
      network.add_ipv4_dynamic_range("192.168.0.1", "192.168.0.10")
      network.del_ipv4_dynamic_range("192.168.0.4", "192.168.0.6")

      ranges = network.dhcp_range_dataset.order(Sequel.asc(:id)).all
      expect(ranges.size).to eq 2
      expect(ranges[0].range_begin.to_s).to eq "192.168.0.1"
      expect(ranges[0].range_end.to_s).to eq "192.168.0.3"
      expect(ranges[1].range_begin.to_s).to eq "192.168.0.7"
      expect(ranges[1].range_end.to_s).to eq "192.168.0.10"
    end

    # "accept?fail? for network address"
    # "accept?fail? for broadcast address"
  end
end
