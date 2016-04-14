# -*- coding: utf-8 -*-

shared_examples "a paging get request" do |fabricator|
  context "with the 'start' parameter set to 2" do
    let(:before_api_call) do
      3.times { Fabricate(fabricator, account_id: account.canonical_uuid) }
    end

    let(:params) { {start: 2} }

    it "It skips the first 2 resources in the database when listing" do
      expect(body.first["total"]).to eq 3
      expect(body.first["start"]).to eq 2
      expect(body.first["limit"]).to eq 250
      expect(body.first["results"].length).to eq 1
    end
  end

  context "with the limit parameter set to 1" do
    let(:before_api_call) do
      2.times { Fabricate(fabricator, account_id: account.canonical_uuid) }
    end

    let(:params) { {limit: 1} }

    it "shows only 1 result" do
      expect(body.first["total"]).to eq 2
      expect(body.first["start"]).to eq 0
      expect(body.first["limit"]).to eq 1
      expect(body.first["results"].length).to eq 1
    end
  end

  context "with the 'sort_by' parameter" do
    let(:before_api_call) { first;second }

    let(:first) { Fabricate(fabricator, account_id: account.canonical_uuid) }
    let(:second) { Fabricate(fabricator, account_id: account.canonical_uuid) }

    context "set to 'asc'" do
      let(:params) { {sort_by: 'asc'} }

      it "sorts the results in ascending order" do
        expect(body.first["results"].first["uuid"]).to eq first.canonical_uuid
        expect(body.first["results"].last["uuid"]).to eq second.canonical_uuid
      end
    end

    context "set to 'desc'" do
      let(:params) { {sort_by: 'desc'} }

      it "sorts the results in descending order" do
        expect(body.first["results"].first["uuid"]).to eq second.canonical_uuid
        expect(body.first["results"].last["uuid"]).to eq first.canonical_uuid
      end
    end

  end
end
