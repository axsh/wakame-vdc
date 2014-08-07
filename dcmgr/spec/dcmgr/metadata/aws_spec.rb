# -*- coding: utf-8 -*-

require 'spec_helper'
require 'yaml'

describe Dcmgr::Metadata::AWS do
  shared_examples 'aws top level metadata' do
    it 'adds a bunch of general aws-like items describing the provided instance' do
      expect(items['ami-id']).to eq inst.image.canonical_uuid
      expect(items['hostname']).to eq inst.hostname
      expect(items['instance-action']).to eq inst.state
      expect(items['instance-id']).to eq inst.canonical_uuid
      expect(items['local-hostname']).to eq inst.hostname
      expect(items['local-ipv4']).to be nil
      expect(items['mac']).to eq inst.nic.first.pretty_mac_addr
      expect(items['public-hostname']).to eq inst.hostname
      expect(items['public-ipv4']).to be nil
      expect(items['x-account-id']).to eq inst.account_id
    end
  end

  shared_examples 'aws metadata for instance without instance-spec in request params' do
    it 'uses Models::Image#instance_model_name for instance-type' do
      expect(items['instance-type']).to eq inst.image.instance_model_name
    end
  end

  describe "#get_items" do
    subject(:items) { Dcmgr::Metadata::AWS.new(inst.to_hash).get_items }

    let(:nic_items) do
      nic_key_regex = /^network\/interfaces\/macs\//
      items.select { |k,v| k.to_s.match(nic_key_regex) }
    end

    context 'with an instance with no keypair and two vnics that don\'t have ips' do
      let(:inst) do
        Fabricate(:instance, request_params: {}) do
          network_vif(count: 2) { Fabricate(:network_vif) }
        end
      end

      #def nic_item(nic, item)
      #  items["network/interfaces/macs/#{nic.pretty_mac_addr}/#{item}"]
      #end

      it_behaves_like 'aws top level metadata'
      it_behaves_like 'aws metadata for instance without instance-spec in request params'

      it 'has no vnic related metadata' do
        expect(nic_items).to be_empty
      end

      it 'has no ssh key related metadata' do
        expect(items['public-keys/']).to be nil
        expect(items['public-keys/0']).to be nil
        expect(items['public-keys/0/openssh-key']).to be nil
      end
    end

    context "without request_params set" do
      let(:inst) { Fabricate(:instance) }

      it 'doesn\'t crash' do
        items
      end
    end
  end
end
