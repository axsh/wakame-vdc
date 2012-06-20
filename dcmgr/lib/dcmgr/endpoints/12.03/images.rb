# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/image'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/images' do
  IMAGE_META_STATE = ['alive', 'alive_with_deleted'].freeze
  IMAGE_STATE=['available', 'attached', 'deleted'].freeze
  IMAGE_STATE_ALL=(IMAGE_STATE + IMAGE_META_STATE).freeze
 
  post do
    # description 'Register new machine image'
    raise NotImplementedError
  end

  get do
    ds = M::Image.dataset

    if params[:state]
      ds = if IMAGE_META_STATE.member?(params[:state])
             case params[:state]
             when 'alive'
               ds.lives
             when 'alive_with_deleted'
               ds.alives_and_deleted
             else
               raise E::InvalidParameter, :state
             end
           elsif IMAGE_STATE.member?(params[:state])
             ds.filter(:state=>params[:state])
           else
             raise E::InvalidParameter, :state
           end
    end
    
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)
    
    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:service_type=>params[:service_type])
    end
    
    collection_respond_with(ds) do |paging_ds|
      R::ImageCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description "Show a machine image details."
    i = find_image_by_uuid(params[:id])
    raise E::UnknownImage, params[:id] if i.nil?

    respond_with(R::Image.new(i).generate)
  end

  delete '/:id' do
    # description 'Delete a machine image'
    i = find_image_by_uuid(params[:id])
    raise E::UnknownImage, params[:id] if i.nil?
    i.destroy
    respond_with([i.canonical_uuid])
  end

  put '/:id' do
    # description 'Update a machine image'
    # param :id, string, :required
    # param :display_name, string, :optional
    # param :description, string, :optional
    raise E::UndefinedImageID if params[:id].nil?
    i = find_image_by_uuid(params[:id])
    raise E::UnknownImage, params[:id] if i.nil?

    i.display_name = params[:display_name] if params[:display_name]
    i.description = params[:description] if params[:description]
    i.save_changes

    commit_transaction
    respond_with(R::Image.new(i).generate)
  end

  def find_image_by_uuid(uuid)
    item = M::Image[uuid] || raise(E::UnknownUUIDResource, uuid.to_s)

    if item.is_public == 1
      # return immediatly when the public flag is set.
    elsif @account && item.account_id != @account.canonical_uuid
      raise E::UnknownUUIDResrouce, uuid.to_s
    end
    if params[:service_type] && params[:service_type] != item.service_type
      raise E::UnknownUUIDResource, uuid.to_s
    end
    item
  end

end
