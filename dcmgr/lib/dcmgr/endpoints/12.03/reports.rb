# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/report'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/reports' do

  # Show list of reports
  # Filter Parameters:
  # uuid:
  # account_id:
  # resource_type:
  # event_type:
  # created_since, created_until:

  get do
    ds = M::AccountingLog.dataset

    if params[:uuid]
      ds = ds.filter(:uuid=>params[:uuid])
    end

    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    if params[:resource_type]
      ds = ds.filter(:resource_type=>params[:resource_type])
    end

    if params[:event_type]
      ds = ds.filter(:event_type=>params[:event_type])
    end

    ds = datetime_range_params_filter(:created, ds)

    collection_respond_with(ds) do |paging_ds|
      R::ReportCollection.new(paging_ds).generate
    end
  end
end
