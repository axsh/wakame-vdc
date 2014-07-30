# -*- coding: utf-8 -*-
require_relative 'helper'

describe "instances" do
  describe "GET" do
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
    end
  end
end


