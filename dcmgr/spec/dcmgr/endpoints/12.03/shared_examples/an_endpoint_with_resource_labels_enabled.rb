# -*- coding: utf-8 -*-

shared_examples "an endpoint with resource labels enabled" do |fabricator, api_suffix|
  describe "GET /:id/labels" do
    let(:resource) { Fabricate(fabricator, account_id: account.canonical_uuid) }

    before(:each) do
      test_resource_uuid = resource.canonical_uuid

      Fabricate(:resource_label) do
        resource_uuid test_resource_uuid
        name "some label"
        value_type 1
        string_value "i am some value"
      end

      Fabricate(:resource_label) do
        resource_uuid test_resource_uuid
        name "some other label"
        value_type 1
        string_value "some other string value"
      end

      get("#{api_suffix}/#{resource.canonical_uuid}/labels", params, headers)
    end


    context "without any parameters" do
      let(:params) { Hash.new }

      it_does_not_crash

      it "Shows all labels belonging to a resource" do
        expect(body.length).to eq 2

        first_result = body[0]
        expect(first_result["resource_uuid"]).to eq resource.canonical_uuid
        expect(first_result["name"]).to eq "some label"
        expect(first_result["value_type"]).to eq 1
        expect(first_result["value"]).to eq "i am some value"

        second_result = body[1]
        expect(second_result["resource_uuid"]).to eq resource.canonical_uuid
        expect(second_result["name"]).to eq "some other label"
        expect(second_result["value_type"]).to eq 1
        expect(second_result["value"]).to eq "some other string value"
      end
    end

    context "with the 'name' parameter" do
      let(:params) { {name: "some label"} }

      it "shows only the labels with the exact name" do
        expect(body.length).to eq 1

        first_result = body[0]
        expect(first_result["resource_uuid"]).to eq resource.canonical_uuid
        expect(first_result["name"]).to eq "some label"
        expect(first_result["value_type"]).to eq 1
        expect(first_result["value"]).to eq "i am some value"
      end
    end
  end
end
