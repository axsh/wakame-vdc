# -*- coding: utf-8 -*-
require_relative 'helper'

describe "instances" do
  M = Dcmgr::Models
  C = Dcmgr::Constants

  describe "POST" do
    let(:online_kvm_host_node) do
      Fabricate(:host_node, hypervisor: C::HostNode::HYPERVISOR_KVM)
    end
    let(:account) { Fabricate(:account) }

    before(:each)  do
      #
      # Stub out isono related methods
      #
      allow(::Dcmgr).to receive(:syncronized_message_ready).and_return(true)

      mock_online_nodes = M::HostNode.where(id: online_kvm_host_node.id)
      allow(M::HostNode).to receive(:online_nodes).and_return mock_online_nodes

      #
      # Make the post request
      #
      post("instances",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
    end

    #
    # TODO: fix crash when account is nil
    # TODO: fix crash when backupobject is nil
    #

    context "with only the required parameters" do
      let(:image) do
        backup_object = Fabricate(:backup_object)

        Fabricate(:image) do
          backup_object_id backup_object.canonical_uuid
        end
      end

      let(:params) do
        {
          image_id: image.canonical_uuid,
          hypervisor: Dcmgr::Constants::HostNode::HYPERVISOR_KVM,
          cpu_cores: 1,
          memory_size: 256
        }
      end

      it "returns json decribing the created instance" do
        expect(body['account_id']).to eq account.canonical_uuid
        expect(body['image_id']).to eq image.canonical_uuid
        expect(body['cpu_cores']).to eq 1
        expect(body['memory_size']).to eq 256
      end

      it "has created a new instance in the database" do
        uuid = body['id']
        expect(M::Instance[uuid]).not_to be_nil
      end
    end
  end

  describe "GET" do
    before(:each)  { get("instances", params) }

    context "with no parameters" do
      let(:params) { Hash.new }

      context "with no instances in the database" do
        it "shows that there are indeed no instances in the database" do
           expect(body).to eq [{
            "total" => 0,
            "start" => 0,
            "limit" => 250,
            "results" => []
           }]
        end
      end

      context "with 3 instances in the database" do
        before(:all) do
          3.times { Fabricate(:instance) }
        end

        it "shows all 3 instances in the database" do
          expect(body.first["total"]).to eq 3
          expect(body.first["results"].size).to eq 3
        end
      end
    end
  end
end


