# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/text_log'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/text_logs' do
  get do
    ds = M::TextLog.dataset

    ds = datetime_range_params_filter(:created, ds)
    collection_respond_with(ds) do |paging_ds|
      R::TextLogCollection.new(paging_ds).generate
    end
  end
end
