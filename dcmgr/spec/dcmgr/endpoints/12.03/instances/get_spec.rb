# -*- coding: utf-8 -*-

require_relative '../helper'
#Dir["#{File.dirname(__FILE__)}/instances/*.rb"].each {|f| require f }

describe Dcmgr::Endpoints::V1203::CoreAPI, "GET instances" do
  let(:account) { Fabricate(:account) }

  let(:headers) do
    { Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid }
  end

  before(:each)  {
    stub_dcmgr_syncronized_message_ready
  }

  context "with no parameters" do
    let(:params) { Hash.new }

    context "with no instances in the database" do
      it "shows that there are indeed no instances in the database" do
        get("instances", params, headers)

        expect(body).to eq [{
         "total" => 0,
         "start" => 0,
         "limit" => 250,
         "results" => []
        }]
      end
    end

    context "with 3 instances in the database" do
      before(:each) do
        3.times { Fabricate(:instance, account_id: account.canonical_uuid) }
        get("instances", params, headers)
      end

      it "shows all 3 instances in the database" do
        expect(body.first["total"]).to eq 3
        expect(body.first["results"].size).to eq 3
      end
    end

    context "with instances belonging to different accountes" do
      before(:each) do
        2.times { Fabricate(:instance, account_id: account.canonical_uuid) }

        Fabricate(:instance, account_id: Fabricate(:account).canonical_uuid)

        get("instances", params, headers)
      end

      it "shows only the instances belonging to the account in the headers" do
        expect(body.first["total"]).to eq 2
        expect(body.first["results"].size).to eq 2
      end
    end
  end
end
