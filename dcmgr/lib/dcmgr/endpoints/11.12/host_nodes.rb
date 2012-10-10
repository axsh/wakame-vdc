# -*- coding: utf-8 -*-

# obsolute path: "/host_pools"
[ '/host_pools', '/host_nodes' ].each do |path|
  Dcmgr::Endpoints::V1112::CoreAPI.namespace path do
    get do
      # description 'Show list of host pools'
      res = select_index(:HostNode, {:start => params[:start],
                           :limit => params[:limit]})
      response_to(res)
    end

    get '/:id' do
      # description 'Show status of the host'
      #param :account_id, :string, :optional
      hp = find_by_uuid(:HostNode, params[:id])
      raise E::UnknownHostNode if hp.nil?
      response_to(hp.to_api_document)
    end
  end
end

