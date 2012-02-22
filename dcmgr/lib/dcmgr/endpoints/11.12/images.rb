# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/images' do
  post do
    # description 'Register new machine image'
    M::Image.lock!
    raise NotImplementedError
  end

  get do
    # description 'Show list of machine images'
    res = select_index(:Image, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  get '/:id' do
    # description "Show a machine image details."
    i = find_by_uuid(:Image, params[:id])
    if !(examine_owner(i) || i.is_public)
      raise E::OperationNotPermitted
    end
    response_to(i.to_api_document(@account.canonical_uuid))
  end

  delete '/:id' do
    # description 'Delete a machine image'
    M::Image.lock!
    i = find_by_uuid(:Image, params[:id])
    if examine_owner(i)
      i.destroy
    else
      raise E::OperationNotPermitted
    end
    response_to([i.canonical_uuid])
  end
end
