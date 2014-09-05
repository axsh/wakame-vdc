# -*- coding: utf-8 -*-

shared_examples "instances_post" do
  describe "POST" do
    use_database_cleaner_strategy_for_this_context :truncation

    #
    # Required resources
    #

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

    #
    # Request parameters and headers
    #

    let(:required_params) do
      {
        image_id: image.canonical_uuid,
        hypervisor: Dcmgr::Constants::HostNode::HYPERVISOR_KVM,
        cpu_cores: 1,
        memory_size: 256
      }
    end

    let(:headers) do
      { Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid }
    end

    #
    # The actual request
    #

    before(:each)  do
      # Stub out all Isono related methods
      stub_dcmgr_syncronized_message_ready
      stub_online_host_nodes M::HostNode.where(id: online_kvm_host_node.id)
      stub_dcmgr_messaging

      suppress_error_logging

      allow(Dcmgr.messaging).to receive(:submit)

      post("instances", params, headers)
    end

    #
    # The tests
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

      context "with no account id in the http headers" do
        let(:headers) { Hash.new }

        it_does_not_crash
      end

      context "when the image provided has nil as its backup object" do
        let(:image) { Fabricate(:image) }

        it_does_not_crash
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

    #TODO: Extract method that checks for non numeric validation
    context "with a non numeric value for cpu_cores" do
      let(:params) { required_params.merge(cpu_cores: 'not a number') }

      it_returns_error(:InvalidParameter, 400, 'cpu_cores')
    end

    context "with a non numeric value for memory_size" do
      let(:params) { required_params.merge(memory_size: 'not a number') }

      it_returns_error(:InvalidParameter, 400, 'memory_size')
    end
  end

end


