# -*- coding: utf-8 -*-
require_relative 'helper'

describe "ssh_key_pairs" do
  before(:each) { stub_dcmgr_syncronized_message_ready }

  let(:account) { Fabricate(:account) }
  let(:headers) do
    { Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid }
  end
  # Contexts can override this let to execute code before the api calls
  let(:before_api_call) {}

  include_examples "an endpoint with resource labels enabled", :ssh_key_pair, 'ssh_key_pairs'

  describe "POST" do
    before(:each) do
      before_api_call

      post("ssh_key_pairs", params, headers)
    end

    example_parameters = {
      display_name: "sir key",
      description: "a key that got padded on the back with a sword by the queen",
      service_type: "std",
      public_key: "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1RVr7PUgF15xm5cE12tuYlwve/F41L+rYXRZllp+7juHUOQj8w8lzmQFMnOyd1jISQ4IK24kX6ysxhWoBZviH6O1mfMWyGdLNqOBx7F8shFDiKJ10aoGoQFY4ZX1oXwDF4NiPAZrE57cqOJCxHidG2Wc1xD//ghWAvVTPVbOqJWb+usJeYfNDrJSjTCvuwOYmbcinMaV6rPOcrAzXQuE8orX2FLnxAJUTXX/TYAbH6HVO3O/XnpDiYH3FKN03YVenufD+gp1pWLuMTqWuwnj7kQ+I2yQw5c5qIYq2GsjHcLVTCRgCEdHX6WlZFVW4jP2XQMU7GrcA+XO69DVQyJHw=="
      #TODO: add test for labels
    }

    context "with no parameters" do
      let(:params) { Hash.new }

      it_does_not_crash

      it "creates a new ssh key pair" do
        expect(M::SshKeyPair.count).to eq 1
      end
    end

    context "without the public key parameter" do
      let (:params) { example_parameters.tap { |ep| ep.delete(:public_key) } }

      it "returns the private key" do
        expect(body["private_key"]).not_to be_empty
      end
    end

    context "with all accepted parameters" do
      let(:params) { example_parameters }

      it "creates a new ssh key pair with all parameters set" do
        expect(last_response).to be_ok
        key_pair = M::SshKeyPair.first

        example_parameters.each do |key, value|
          expect(key_pair[key]).to eq(value)
        end
      end
    end

    example_parameters.each do |key, value|
      context "with only the '#{key}' parameter" do
        let(:params) { { key => value } }

        it "creates a new ssh key pair with '#{key}' set" do
          expect(last_response).to be_ok
          expect(M::SshKeyPair.first[key]).to eq(value)
        end
      end
    end
  end

  describe "GET /:id" do
    before(:each) do
      before_api_call

      get("ssh_key_pairs/#{object_id}", {}, headers)
    end

    context "with an existing key pair id" do
      let(:key_pair) { Fabricate(:ssh_key_pair, account_id: account.canonical_uuid) }
      let(:object_id) { key_pair.canonical_uuid }

      it "shows the key pair" do
        expect(body).to eq({
          "id" => key_pair.canonical_uuid,
          "account_id" => key_pair.account_id,
          "uuid" => key_pair.canonical_uuid,
          "finger_print" => key_pair.finger_print,
          "public_key" => key_pair.public_key,
          "display_name" => key_pair.display_name,
          "description" => key_pair.description.to_s,
          "created_at" => key_pair.created_at.iso8601,
          "updated_at" => key_pair.updated_at.iso8601,
          "service_type" => key_pair.service_type,
          "deleted_at" => key_pair.deleted_at,
          "labels" => []
        })
      end
    end

    it_behaves_like 'a get request describing a single resource', :ssh_key_pair, M::SshKeyPair

  end

  describe "GET" do
    before(:each) do
      before_api_call

      get("ssh_key_pairs", params, headers)
    end

    it_behaves_like 'a paging get request', :ssh_key_pair
    it_behaves_like 'a get request with datetime range filtering', :created, :ssh_key_pair
    it_behaves_like 'a get request with datetime range filtering', :deleted, :ssh_key_pair, {with_deleted: true}

    context "with no parameters" do

      let(:params) { Hash.new }

      context "with no ssh keys in the database" do
        it "returns an empty list of results" do
          expect(body).to eq [{
           "total" => 0,
           "start" => 0,
           "limit" => 250,
           "results" => []
          }]
        end
      end

      context "with ssh keys in the database" do
        let(:before_api_call) do
          3.times { Fabricate(:ssh_key_pair, account_id: account.canonical_uuid) }

          Fabricate(:ssh_key_pair, account_id: Fabricate(:account).canonical_uuid)
        end

        it "shows only the ones belonging the the requester's account" do
          expect(body.first["total"]).to eq 3
          expect(body.first["results"].size).to eq 3
        end
      end

      context "with deleted ssh keys in the database" do
        let(:before_api_call) do
          3.times { Fabricate(:ssh_key_pair, account_id: account.canonical_uuid).destroy }
        end

        it "does not show the deleted keys" do
          expect(body).to eq [{
           "total" => 0,
           "start" => 0,
           "limit" => 250,
           "results" => []
          }]
        end
      end
    end

    context "with the 'service type' parameter" do
      let(:before_api_call) do
        Fabricate(:ssh_key_pair, account_id: account.canonical_uuid,
                                 service_type: 'std')

        Fabricate(:ssh_key_pair, account_id: account.canonical_uuid,
                                 service_type: 'lb')
      end

      let(:params) { { service_type: 'std' } }

      it "shows only keys with the provided service type" do
        expect(body.first["total"]).to eq 1
        expect(body.first["results"].first["service_type"]).to eq "std"
      end
    end

    context "with the 'display name' parameter" do
      let(:before_api_call) do
        Fabricate(:ssh_key_pair, account_id: account.canonical_uuid,
                                 display_name: 'joske')

        Fabricate(:ssh_key_pair, account_id: account.canonical_uuid,
                                 display_name: 'jefke')
      end

      let(:params) { { display_name: 'joske' } }

      it "shows only keys with the provided display name" do
        expect(body.first["total"]).to eq 1
        expect(body.first["results"].first["display_name"]).to eq "joske"
      end
    end
  end
end
