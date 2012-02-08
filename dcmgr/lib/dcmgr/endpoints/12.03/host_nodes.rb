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
    hn = M::HostNode.create(params)
    response_to(hn.to_api_document)
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
    response_to(hn.to_api_document)
  end
end
