# -*- coding: utf-8 -*-
require_relative 'helper'

describe "ssh_key_pairs" do
  before(:each) { stub_dcmgr_syncronized_message_ready }

  let(:account) { Fabricate(:account) }
  # Contexts can override this let to execute code before the api calls
  let(:before_api_call) {}

  describe "POST" do
    before(:each) do
      before_api_call

      post("ssh_key_pairs",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
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

  describe "GET" do
    context "with no parameters" do
      before(:each) do
        before_api_call

        get("ssh_key_pairs",
             params,
             Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
      end

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
  end
end
