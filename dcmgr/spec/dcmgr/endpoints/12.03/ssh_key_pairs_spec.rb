# -*- coding: utf-8 -*-
require_relative 'helper'

describe "ssh_key_pairs" do
  describe "POST" do
    let(:account) { Fabricate(:account) }

    before(:each) do
      stub_dcmgr_syncronized_message_ready

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
end
