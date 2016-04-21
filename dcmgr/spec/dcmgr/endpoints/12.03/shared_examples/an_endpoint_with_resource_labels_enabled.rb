# -*- coding: utf-8 -*-

shared_examples "an endpoint with resource labels enabled" do |fabricator, api_suffix|
  let(:resource) { Fabricate(fabricator, account_id: account.canonical_uuid) }

  describe "GET /:id/labels" do

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

      Fabricate(:resource_label) do
        resource_uuid test_resource_uuid
        name "yet another label"
        value_type 1
        string_value "there's no place like... I wanna be a witch!"
      end

      get("#{api_suffix}/#{resource.canonical_uuid}/labels", params, headers)
    end


    context "without any parameters" do
      let(:params) { Hash.new }

      it_does_not_crash

      it "Shows all labels belonging to a resource" do
        expect(body.length).to eq 3

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

        third_result = body[2]
        expect(third_result["resource_uuid"]).to eq resource.canonical_uuid
        expect(third_result["name"]).to eq "yet another label"
        expect(third_result["value_type"]).to eq 1
        expect(third_result["value"]).to eq "there's no place like... I wanna be a witch!"
      end
    end

    context "with the 'name' parameter" do
      let(:params) { {name: "some"} }

      it_does_not_crash

      it "shows only the labels whose name starts with the pattern provided" do
        expect(body.length).to eq 2

        expect(body[0]["name"]).to eq "some label"
        expect(body[1]["name"]).to eq "some other label"
      end
    end

    context "with SQL injected into the 'name' parameter" do
      let(:params) do
        { name: "blah; insert into resource_labels values(10, \"aa\", \"aa\", 1, \"\", \"\", Now(), Now());" }
      end

      it "does not execute the provided SQL statement" do
        expect(M::ResourceLabel.filter(id: 10)).to be_empty
      end
    end
  end

  [:post, :put].each do |verb|
    describe "#{verb.to_s.upcase} /:id/labels/:name" do
      before(:each) { send(verb, "#{api_suffix}/#{resource.canonical_uuid}/labels/joske", params, headers) }

      context "with a correct name/value pair" do
        let(:params) { { value: 'jefke'} }

        it "sets a resource label with the name and value" do
          expect(resource.resource_labels_dataset.count).to eq 1

          label = resource.resource_labels.first
          expect(label.name).to eq "joske"
          expect(label.string_value).to eq "jefke"
        end
      end
    end

    describe "#{verb.to_s.upcase} /:id/labels/:name" do
      before(:each) { send(verb, "#{api_suffix}/#{resource.canonical_uuid}/labels", params, headers) }

      context "with two array parameters called name and value" do
        let(:params) do
          {
            name: ["a", "b", "c"],
            value: ["1", "2", "3"]
          }
        end

        it "sets a resource label for each name/value pair" do
          expect(resource.resource_labels_dataset.count).to eq 3

          labels = resource.resource_labels_dataset
          expect(labels.where(name: "a").first.value).to eq "1"
          expect(labels.where(name: "b").first.value).to eq "2"
          expect(labels.where(name: "c").first.value).to eq "3"
        end
      end
    end

  end
end
