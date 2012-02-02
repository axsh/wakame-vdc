# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/storage_nodes' do
  get do
    # description 'Show lists of the storage_pools'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:StorageNode, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end
  
  get '/:id' do
    # description 'Show the storage_pool status'
    # params id, string, required
    pool_id = params[:id]
    raise E::UndefinedStorageNodeID if pool_id.nil?
    vs = find_by_uuid(:StorageNode, pool_id)
    raise E::UnknownStorageNode if vs.nil?
    response_to(vs.to_api_document)
  end
  
  post do
    sn = M::StorageNode.create(params)
    response_to(sn.to_api_document)
  end
  
  delete '/:id' do
    sn = find_by_uuid(:StorageNode, params[:id])
    sn.delete
    response_to({:uuid=>sn.canonical_uuid})
  end
end
