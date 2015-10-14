# -*- coding: utf-8 -*-
require_relative 'helper'

describe "virtual_data_center_specs" do
  M = Dcmgr::Models
  C = Dcmgr::Constants

  use_database_cleaner_strategy_for_this_context :truncation

  let(:account) { Fabricate(:account) }

  let(:online_kvm_host_node) do
    Fabricate(:host_node, hypervisor: C::HostNode::HYPERVISOR_KVM)
  end

  let(:host_node_group) do
    Fabricate(:host_node_group, uuid: "kvm")
  end

  let(:image) do
    backup_object = Fabricate(:backup_object)
    Fabricate(:image) do
      backup_object_id backup_object.canonical_uuid
    end
  end

  let(:ssh_key_pair) do
    Fabricate(:ssh_key_pair)
  end

  let(:spec) do
    {
      file: "---
vdc_name: sample

instance_spec:
  small:
    cpu_cores: 1
    memory_size: 512
    host_node_group: #{host_node_group.canonical_uuid}
    hypervisor: #{Dcmgr::Constants::HostNode::HYPERVISOR_KVM}
    quota_weight: 1.0

vdc_spec:
  sample_api:
    instance_spec: small
    image_id: #{image.canonical_uuid}
    ssh_key_id: #{ssh_key_pair.canonical_uuid}
    vifs:
      eth0:
        index: 0
        network: nw-demo
        security_groups: sg-demo
    user_data:
      port: 8080
"
    }
  end

  before(:each) do
    # Stub out all Isono related methods
    stub_dcmgr_syncronized_message_ready
    stub_online_host_nodes M::HostNode.where(id: online_kvm_host_node.id)
    stub_dcmgr_messaging
    allow(Dcmgr.messaging).to receive(:submit)
  end

  describe "POST" do
    before(:each) do
      post("virtual_data_center_specs",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
    end

    let(:params) { spec }

    context 'with only the required parameter' do
      it 'retruns json describing the created virtual data center spcec' do
        expect(body['account_id']).to eq account.canonical_uuid
      end
    end
  end

  describe "GET" do
    before(:each) { get("virtual_data_center_specs", params) }

    context "with no parameters" do
      let(:params) { Hash.new }

      context "with no virtual_data_center_specs in the database" do
        it "shows that there are indeed no virtual_data_center_spec in the database" do
          expect(body).to eq [{
                                "total" => 0,
                                "start" => 0,
                                "limit" => 250,
                                "results" => []
                              }]
        end
      end

    end
  end
end
