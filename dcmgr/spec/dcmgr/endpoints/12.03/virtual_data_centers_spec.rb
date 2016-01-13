# -*- coding: utf-8 -*-
require_relative 'helper'

describe "virtual_data_centers" do
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

  let(:network) do
    dc_network = Fabricate(:dc_network)
    Fabricate(:network, dc_network_id: dc_network.id )
  end

  let(:spec) do
    {
      file: "---
display_name: sample

security_groups:
  dcmgr_group:
    rules: |
      # webapi and webui port
      tcp:9000,9001,ip4:0.0.0.0
      # amqp port
      tcp:5672,5672,ip4:0.0.0.0
  db_group:
    rules: 'tcp:3306,3306,dcmgr_group'

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
        network: #{network.canonical_uuid}
        security_groups: []
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
    allow(Dcmgr.messaging).to receive(:event_publish)
  end

  describe "POST" do
    before(:each)  do
      post("virtual_data_centers",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
    end

    let(:vdc_spec_id) do
      post("virtual_data_center_specs",
           spec,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)

      body['uuid']
    end

    context 'with the required parameter: vdc_spec_id' do
      let(:params) { {vdc_spec: vdc_spec_id } }

      it 'returns json describing the created virtual data center' do
        expect(last_response).to succeed.with_body_containing({
          account_id: account.canonical_uuid
        })
      end

      it 'has created a new virtual data center in the database' do
        uuid = body['uuid']
        expect(M::VirtualDataCenter[uuid]).not_to be_nil
      end

      it 'has created a new instance in the database' do
        uuid = body['instances'].first['uuid']
        expect(M::Instance[uuid]).not_to be_nil
      end

      #TODO: Tests to make sure that names in spec files are unique
      it 'has created the security groups in the database' do
        expect(last_response).to succeed

        expect(body['vdc_spec']['security_groups'].keys).to match_array(['dcmgr_group',
                                                                         'db_group'])

        vdc = M::VirtualDataCenter[body['uuid']]
        sgs = vdc.security_groups
        expect(sgs.size).to eq(2)

        dcmgr_group = sgs.find { |sg| sg[:name_in_virtual_data_center_spec] == 'dcmgr_group' }
        db_group = sgs.find { |sg| sg[:name_in_virtual_data_center_spec] == 'db_group' }

        expect(dcmgr_group).not_to be_nil
        expect(db_group).not_to be_nil

        expect(dcmgr_group.display_name).to eq "#{vdc.canonical_uuid} dcmgr_group"
        expect(db_group.display_name).to eq "#{vdc.canonical_uuid} db_group"

        expect(dcmgr_group.rule).to eq "# webapi and webui port
tcp:9000,9001,ip4:0.0.0.0
# amqp port
tcp:5672,5672,ip4:0.0.0.0
"

        expect(db_group.rule).to eq "tcp:3306,3306,#{dcmgr_group.canonical_uuid}"
      end
    end

    context 'with a malformed vdc_spec_id' do
      let(:params) { {vdc_spec: "i am not a uuid"} }

      it_fails_with_error 400,
                          'Dcmgr::Endpoints::Errors::InvalidParameter',
                          'Invalid UUID Syntax: i am not a uuid'


    end
  end

  describe "GET" do
    before(:each) { get("virtual_data_centers", params) }

    context "with no parameters" do
      let(:params) { Hash.new }

      context "with no virtual_data_centers in the database" do
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
