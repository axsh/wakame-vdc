# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/instance_specs' do
  get do
    # description 'Show list of instance template'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:InstanceSpec, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  get '/:id' do
    # description "Show the instance template"
    # params :id required
    inst_spec = find_by_uuid(:InstanceSpec, params[:id])
    response_to(inst_spec.to_api_document)
  end
end
