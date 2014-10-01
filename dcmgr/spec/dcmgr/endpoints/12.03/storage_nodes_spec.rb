# -*- coding: utf-8 -*-
require_relative 'helper'

describe "storage_nodes" do
  M = Dcmgr::Models
  C = Dcmgr::Constants

  describe "GET" do
    before(:each)  { get("storage_nodes", params) }

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
          3.times { Fabricate(:storage_node) }
        end

        it "shows all 3 instances in the database" do
          expect(body.first["total"]).to eq 3
          expect(body.first["results"].size).to eq 3
        end
      end
    end
  end
end


