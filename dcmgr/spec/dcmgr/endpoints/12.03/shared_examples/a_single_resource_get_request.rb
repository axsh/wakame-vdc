# -*- coding: utf-8 -*-

shared_examples 'a get request describing a single resource' do |fabricator, model|
  context "with an existing network belonging to a different account" do
    let(:object_id) do
      other_acc = Fabricate(:account)
      Fabricate(fabricator, account_id: other_acc.canonical_uuid).canonical_uuid
    end

    it_returns_error(:UnknownUUIDResource, 404)
  end

  context "with a non existing uuid" do
    let(:object_id) { "#{model.uuid_prefix}-nothere" }

    it_returns_error(:UnknownUUIDResource, 404)
  end

  context "with a malformed uuid" do
    let(:object_id) { "koekenbakkenvlaaien" }

    it_returns_error(:InvalidParameter, 400, "Invalid UUID Syntax: koekenbakkenvlaaien")
  end
end
