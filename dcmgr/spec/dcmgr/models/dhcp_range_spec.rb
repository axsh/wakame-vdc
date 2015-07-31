require_relative "helper"

describe Dcmgr::Models::DhcpRange do
  context "#hit_ranges" do
    let(:network) { Fabricate(:network) }

    let!(:range_1) do
      Fabricate(:dhcp_range, network: network,
                             range_begin: IPAddress("192.168.0.10").to_i,
                             range_end: IPAddress("192.168.0.20").to_i)
    end

    let!(:range_2) do
      Fabricate(:dhcp_range, network: network,
                             range_begin: IPAddress("192.168.0.50").to_i,
                             range_end: IPAddress("192.168.0.70").to_i)
    end

    let!(:range_3) do
      Fabricate(:dhcp_range, network: network,
                             range_begin: IPAddress("192.168.0.90").to_i,
                             range_end: IPAddress("192.168.0.130").to_i)
    end

    it "finds the range for a single IP Address" do
      test_ip = IPAddress("192.168.0.15").to_i
      hits = network.dhcp_range_dataset.hit_ranges(test_ip)

      expect(hits.all).to eq [range_1]
    end

    it "finds the range for multiple IP addresses in the same range" do
      test_ip_1 = IPAddress("192.168.0.15").to_i
      test_ip_2 = IPAddress("192.168.0.17").to_i

      hits = network.dhcp_range_dataset.hit_ranges(test_ip_1, test_ip_2)

      expect(hits.all).to eq [range_1]
    end

    it "finds the range for multiple IP addresses in different ranges" do
      test_ip_1 = IPAddress("192.168.0.15").to_i
      test_ip_2 = IPAddress("192.168.0.60").to_i
      test_ip_3 = IPAddress("192.168.0.120").to_i

      hits = network.dhcp_range_dataset.hit_ranges(test_ip_1,
                                                   test_ip_2,
                                                   test_ip_3)

      expect(hits.all).to eq [range_1, range_2, range_3]
    end

    it "finds the correct ranges for IP addresses that are the begin or end point of a range" do
      test_ip_1 = IPAddress("192.168.0.10").to_i
      test_ip_2 = IPAddress("192.168.0.130").to_i

      hits = network.dhcp_range_dataset.hit_ranges(test_ip_1, test_ip_2)

      expect(hits.all).to eq [range_1, range_3]
    end

    it "returns an empty set when there were no matches" do
      test_ip_1 = IPAddress("192.168.0.30").to_i
      test_ip_2 = IPAddress("192.168.0.80").to_i

      hits = network.dhcp_range_dataset.hit_ranges(test_ip_1, test_ip_2)

      expect(hits).to be_empty
    end

    it "still returns the correct range when one of the arguments matched and the other didn't" do
      test_ip_1 = IPAddress("192.168.0.12").to_i
      test_ip_2 = IPAddress("192.168.0.80").to_i

      hits = network.dhcp_range_dataset.hit_ranges(test_ip_1, test_ip_2)

      expect(hits.all).to eq [range_1]
    end
  end
end
