# -*- coding: utf-8 -*-

# obsolute path: "/storage_pools"
[ '/storage_pools', '/storage_nodes' ].each do |path|
  Dcmgr::Endpoints::V1112::CoreAPI.namespace path do
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
  end
end

