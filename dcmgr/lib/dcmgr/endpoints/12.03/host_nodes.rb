# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/host_node'

Dcmgr::Endpoints::V1203::CoreAPI.namespace('/host_nodes') do
  get do
    ds = M::HostNode.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)
    
    collection_respond_with(ds) do |paging_ds|
      R::HostNodeCollection.new(paging_ds).generate
    end
  end
  
  get '/:id' do
    # description 'Show status of the host'
    # param :account_id, :string, :optional
    hn = find_by_uuid(:HostNode, params[:id])
    
    respond_with(R::HostNode.new(hn).generate)
  end
  
  post do
    hn = M::HostNode.create(params)
    respond_with(R::HostNode.new(hn).generate)
  end

  delete '/:id' do
    hn = find_by_uuid(:HostNode, params[:id])
    hn.destroy
    response_to({:uuid=>hn.canonical_uuid})
  end

  put '/:id' do
    hn = find_by_uuid(:HostNode, params[:id])

    changed = {}
    (M::HostNode.columns - [:id]).each { |c|
      if params.has_key?(c.to_s)
        changed[c] = params[c]
      end
    }

    hn.update_fields(changed, changed.keys)
    respond_with(R::HostNode.new(hn).generate)
  end
end
