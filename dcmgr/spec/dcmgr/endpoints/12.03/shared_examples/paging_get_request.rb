# -*- coding: utf-8 -*-

shared_examples "paging get request" do |fabricator|
  context "with the 'start' parameter set to 2" do
    let(:before_api_call) do
      2.times { Fabricate(fabricator, account_id: account.canonical_uuid) }
      Fabricate(fabricator, account_id: account.canonical_uuid)
    end

    let(:params) { {start: 2} }

    it "It skips the first 2 resources in the database when listing" do
      expect(body.first["total"]).to eq 3
      expect(body.first["start"]).to eq 2
      expect(body.first["limit"]).to eq 250
      expect(body.first["results"].length).to eq 1
    end
  end
end
