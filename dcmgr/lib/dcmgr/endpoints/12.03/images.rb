# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/image'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/images' do
  post do
    # description 'Register new machine image'
    raise NotImplementedError
  end

  get do
    # description 'Show list of machine images'
    ds = M::Image.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)
    
    collection_respond_with(ds) do |paging_ds|
      R::ImageCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description "Show a machine image details."
    i = find_by_uuid(:Image, params[:id])

    respond_with(R::Image.new(i).generate)
  end

  delete '/:id' do
    # description 'Delete a machine image'
    i = find_by_uuid(:Image, params[:id])
    if examine_owner(i)
      i.destroy
    else
      raise E::OperationNotPermitted
    end
    respond_with([i.canonical_uuid])
  end
end
