# -*- coding: utf-8 -*-

require 'spec_helper'
require 'yaml'

def it_does_not_crash
  it 'doesn\'t crash' do
    items
  end
end

describe Dcmgr::Metadata do
  describe Dcmgr::Metadata::AWS do
    let(:inst) { Fabricate(:instance) }
    let(:items) { Dcmgr::Metadata::AWS.new(inst.to_hash).get_items }

    context 'with all settings to make it work' do
      let(:inst) do
        Fabricate(:instance,
          request_params: {}
        )
      end

      it 'sets metadata items that mimic the aws metadata layout' do
        expect(items['ami-id']).to eq inst.image.canonical_uuid
      end
    end

    context "without request_params set" do
      it_does_not_crash
    end
  end
end
