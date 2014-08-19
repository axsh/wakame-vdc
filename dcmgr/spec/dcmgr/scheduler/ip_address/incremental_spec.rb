# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/incremental_examples/*.rb"].each {|f| require f }

describe Dcmgr::Scheduler::IPAddress::Incremental do
  include NetworkHelper

  describe "#schedule" do
    let(:network_vif) { Fabricate(:network_vif, network: network) }
    let(:incremental) { Dcmgr::Scheduler::IPAddress::Incremental.new }

    describe "sad paths" do
      subject { lambda { incremental.schedule(options) } }

      include_examples "fail argument checks"
      include_examples "dhcp range exhausted"
    end

    describe "happy paths" do
      subject do
        incremental.schedule(options)

        network_vif
      end

      let(:options) { network_vif }

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
          expect(subject.direct_ip_lease.first.ipv4).to eq "192.168.0.10"
        end
      end

      context "with a default gateway set in the dhcp range" do
        context "as the first address" do
          let(:network) do
            n = Fabricate(:network, ipv4_network: "192.168.0.0",
                                    ipv4_gw: "192.168.0.1")

            set_dhcp_range(n, "192.168.0.1", "192.168.0.5")

            n
          end

          it "should be skipped when scheduling ip addresses for vnics" do
            expect(subject.direct_ip_lease.first.ipv4).to eq "192.168.0.2"
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

          it "should be skipped when scheduling ip addresses for vnics" do
            expect(subject.direct_ip_lease.first.ipv4).to eq "192.168.0.4"
          end
        end
      end
    end
  end
end
