# -*- coding: utf-8 -*-

require 'spec_helper'
require 'yaml'

require_relative 'aws_shared_examples'

shared_context 'get_items' do
  subject(:items) { described_class.new(inst.to_hash).get_items }

  let(:inst) { Fabricate(:instance) }
end

shared_examples 'aws metadata' do
  describe "#get_items" do
    include_context 'get_items'

    let(:nic_items) do
      nic_key_regex = /^network\/interfaces\/macs\//
      items.select { |k,v| k.to_s.match(nic_key_regex) }
    end

    it 'doesn\'t crash' do
      items
    end

    context 'with an instance with no keypair and two vnics that don\'t have ips' do
      let(:inst) do
        Fabricate(:instance, request_params: {}) do
          network_vif(count: 2) { Fabricate(:network_vif) }
        end
      end

      it_behaves_like 'aws top level metadata'
      it_behaves_like 'aws metadata for instance with vnics'
      it_behaves_like 'aws metadata for instance without ip leases'
      it_behaves_like 'aws metadata for instance without instance-spec in request params'
      it_behaves_like 'aws metadata for instance without ssh keypair'
    end

    context 'with an instance with no keypair and two vnics with ip leases' do
      let(:inst) do
        Fabricate(:instance, request_params: {}) do
          network_vif(count: 2) { Fabricate(:network_vif_with_ip) }
        end
      end

      it_behaves_like 'aws top level metadata'
      it_behaves_like 'aws metadata for instance with vnics'
      it_behaves_like 'aws metadata for instance with ip leases'
      it_behaves_like 'aws metadata for instance without instance-spec in request params'
      it_behaves_like 'aws metadata for instance without ssh keypair'
    end

    context "with an instance with a ssh keypair set" do
      let(:inst) do
        Fabricate(:instance, request_params: {}) do
          ssh_key_pair { Fabricate(:ssh_key_pair) }
        end
      end

      it_behaves_like 'aws top level metadata'
      it_behaves_like 'aws metadata for instance with ssh keypair'
    end
  end
end

describe Dcmgr::Metadata::AWS do
  it_behaves_like 'aws metadata'
end

describe Dcmgr::Metadata::AWSWithFirstBoot do
  it_behaves_like 'aws metadata'

  describe '#get_items' do
    include_context 'get_items'

    it 'Creates a first-boot file' do
      expect(items['first-boot']).to eq ''
    end
  end
end
