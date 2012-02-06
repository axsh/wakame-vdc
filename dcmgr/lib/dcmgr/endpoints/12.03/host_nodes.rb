# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1203::CoreAPI.namespace('/host_nodes') do
  get do
    # description 'Show list of host node'
    res = select_index(:HostNode, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end
  
  get '/:id' do
    # description 'Show status of the host'
    # param :account_id, :string, :optional
    hn = find_by_uuid(:HostNode, params[:id])
    raise OperationNotPermitted unless examine_owner(hn)
    
    response_to(hn.to_api_document)
  end
  
  post do
    hn = Dcmgr::Models::HostNode.create(params)
    response_to(hn.to_api_document)
  end
  
  delete '/:id' do
    hn = find_by_uuid(:HostNode, params[:id])
    hn.delete
    response_to({:uuid=>hn.canonical_uuid})
  end
end
