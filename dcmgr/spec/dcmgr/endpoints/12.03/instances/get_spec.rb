# -*- coding: utf-8 -*-

require_relative '../helper'
#Dir["#{File.dirname(__FILE__)}/instances/*.rb"].each {|f| require f }

describe Dcmgr::Endpoints::V1203::CoreAPI, "GET instances" do
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
