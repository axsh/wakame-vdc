# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/incremental_examples/*.rb"].each {|f| require f }

describe Dcmgr::Scheduler::IPAddress::Incremental do
  include NetworkHelper

  describe '#schedule' do
    let(:network_vif) { Fabricate(:network_vif, network: network) }
    let(:incremental) { Dcmgr::Scheduler::IPAddress::Incremental.new }

    describe 'sad paths' do
      subject { lambda { incremental.schedule(options) } }

      include_examples 'fail argument checks'
      include_examples 'dhcp range exhausted'
    end

    describe 'happy paths' do
      subject do
        incremental.schedule(network_vif)

        network_vif.direct_ip_lease.first.ipv4
      end

      include_examples 'first ip in range'
      include_examples 'one range full, one empty'
      include_examples 'gateway in dhcp range'
      include_examples 'wraparound dhcp range'
      include_examples 'reassign released addresses'

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
  end
end
