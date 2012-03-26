# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/storage_node'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/storage_nodes' do
  get do
    # description 'Show lists of the storage_pools'
    ds = M::StorageNode.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)
    
    if params[:node_id]
      ds = ds.filter(:node_id=>params[:node_id])
    end

    collection_respond_with(ds) do |paging_ds|
      R::StorageNodeCollection.new(paging_ds).generate
    end
  end
  
  get '/:id' do
    # description 'Show the storage_pool status'
    # params id, string, required
    pool_id = params[:id]
    raise E::UndefinedStorageNodeID if pool_id.nil?
    sn = find_by_uuid(:StorageNode, pool_id)
    raise E::UnknownStorageNode if sn.nil?
    respond_with(R::StorageNode.new(sn).generate)
  end
  
  post do
    sn = M::StorageNode.create(params)
    respond_with(R::StorageNode.new(sn).generate)
  end
  
  delete '/:id' do
    sn = find_by_uuid(:StorageNode, params[:id])
    raise E::UnknownStorageNode if sn.nil?
    sn.destroy
    respond_with(R::StorageNode.new(sn).generate)
  end

  put '/:id' do
    sn = find_by_uuid(:StorageNode, params[:id])
    raise E::UnknownStorageNode if sn.nil?

    changed = {}
    (M::StorageNode.columns - [:id]).each { |c|
      if params.has_key?(c.to_s)
        changed[c] = params[c]
      end
    }

    sn.update_fields(changed, changed.keys)
    respond_with(R::StorageNode.new(sn).generate)
  end
end
