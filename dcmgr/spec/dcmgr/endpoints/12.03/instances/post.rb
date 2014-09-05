# -*- coding: utf-8 -*-

shared_examples "instances_post" do
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

    let(:required_params) do
      {
        image_id: image.canonical_uuid,
        hypervisor: Dcmgr::Constants::HostNode::HYPERVISOR_KVM,
        cpu_cores: 1,
        memory_size: 256
      }
    end


    before(:each)  do
      # Stub out all Isono related methods
      stub_dcmgr_syncronized_message_ready
      stub_online_host_nodes M::HostNode.where(id: online_kvm_host_node.id)
      stub_dcmgr_messaging

      allow(Dcmgr.messaging).to receive(:submit)

      post("instances",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
    end

    #
    # TODO: fix crash when account is nil
    # TODO: fix crash when backupobject is nil
    #

    context "with only the required parameters" do
      let(:params) { required_params }

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

      it "has sent a message to collector to schedule the new instance" do
        expect(Dcmgr.messaging).to have_received(:submit).with("scheduler",
                                                               "schedule_instance",
                                                               body['id'])
      end
    end

    context "with a machine image uuid that doesn't exist" do
      let(:params) { required_params.merge(image_id: "wmi-nothere") }

      it_returns_error(:InvalidImageID, 400)
    end

    context "with a machine image uuid with a malformed synax" do
      let(:params) { required_params.merge(image_id: "i am not a uuid") }

      error_msg = "Dcmgr::Models::InvalidUUIDError: Invalid uuid or unsupported" +
                  " uuid: i am not a uuid in Dcmgr::Models::Image"

      it_returns_error(:DatabaseError, 400, error_msg)
    end
  end

end


