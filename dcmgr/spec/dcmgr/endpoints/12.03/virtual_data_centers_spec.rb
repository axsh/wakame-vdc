# -*- coding: utf-8 -*-
require_relative 'helper'

describe "virtual_data_centers" do
  M = Dcmgr::Models
  C = Dcmgr::Constants

  describe "POST" do
    use_database_cleaner_strategy_for_this_context :truncation

    let(:account) { Fabricate(:account) }

    let(:online_kvm_host_node) do
      Fabricate(:host_node, hypervisor: C::HostNode::HYPERVISOR_KVM)
    end

    let(:image) do
      backup_object = Fabricate(:backup_object)

      Fabricate(:image) do
        backup_object_id backup_object.canonical_uuid
      end
    end

    before(:each)  do
      # Stub out all Isono related methods
      stub_dcmgr_syncronized_message_ready
      stub_online_host_nodes M::HostNode.where(id: online_kvm_host_node.id)
      stub_dcmgr_messaging

      allow(Dcmgr.messaging).to receive(:submit)

      post("virtual_data_centers",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
    end

    context 'with only the required parameters' do
      let(:params) do
        {
          type: "docker",
          spec: "small",
        }
      end

      it 'returns json describing the created virtual data center' do
        expect(body['account_id']).to eq account.canonical_uuid
      end
    end

    context 'with the required and optional parameters' do
      let(:params) do
        {
          type: "docker",
          spec: "small",
          spec_file: "---
instance_spec:
  small:
    cpu_cores: 1
    memory_size: 512
    host_node_group: hng-local
    hypervisor: #{Dcmgr::Constants::HostNode::HYPERVISOR_KVM}
    quota_weight: 1.0
vdc_spec:
  docker_api:
    instance_type: docker
    instance_spec: small
    image_id: #{image.canonical_uuid}
    user_data:
      port: 8080
",
        }
      end

      it 'returns json describing the created virtual data center' do
        expect(body['account_id']).to eq account.canonical_uuid
      end

      it 'has created a new virtual data center in the database' do
        uuid = body['uuid']
        expect(M::VirtualDataCenter[uuid]).not_to be_nil
      end

      it 'has created a new instance in the database' do
        uuid = body['instances'].first['uuid']
        expect(M::Instance[uuid]).not_to be_nil
      end
    end
  end

  describe "GET" do
  end
end 
