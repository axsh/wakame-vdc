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

  describe "POST" do
    before(:each) do
      before_api_call

      post("ssh_key_pairs", params, headers)
    end

    context "with no parameters" do
      let(:params) { Hash.new }

      it "doesn't crash" do
        if !last_response.errors.empty?
          raise "The API call crashed.\n#{last_response.errors}"
        end
      end
    end
  end

  describe "GET /:id" do
    before(:each) do
      before_api_call

      get("ssh_key_pairs/#{key_pair_id}", {}, headers)
    end

    context "with an existing key pair id" do
      let(:key_pair) { Fabricate(:ssh_key_pair, account_id: account.canonical_uuid) }
      let(:key_pair_id) { key_pair.canonical_uuid }

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
  end

  describe "GET" do
    before(:each) do
      before_api_call

      get("ssh_key_pairs", params, headers)
    end

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
