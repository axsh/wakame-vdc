# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/image'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/images' do
  IMAGE_META_STATE = ['alive', 'alive_with_deleted'].freeze
  IMAGE_STATE=['available', 'deleted'].freeze
  IMAGE_STATE_ALL=(IMAGE_STATE + IMAGE_META_STATE).freeze

  register V1203::Helpers::ResourceLabel
  enable_resource_label(M::Image)

  post do
    # description 'Register new machine image'
    raise NotImplementedError
  end

  get do
    ds = M::Image.dataset

    scope = {}
    if params[:account_id]
      scope[:account_id]=params[:account_id]
    end

    unless params[:is_public].blank?
      scope[:is_public]=  case params[:is_public]
                          when 'true', 'false'
                            params[:is_public].to_s == 'true' ? 1 : 0
                          when '1', '0'
                            params[:is_public].to_i
                          else
                            raise E::InvalidParameter, :is_public
                          end
    end
    unless scope.empty?
      ds = ds.filter( scope.map {|k,v| "#{k} = ?" }.join(' OR '), *scope.values )
    end

    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:service_type=>params[:service_type])
    end

    if params[:state]
      ds = case params[:state]
           when *IMAGE_META_STATE
             case params[:state]
             when 'alive'
               ds.lives
             when 'alive_with_deleted'
               ds.alives_and_deleted
             else
               raise E::InvalidParameter, :state
             end
           when *IMAGE_STATE
             ds.filter(:state=>params[:state])
           else
             raise E::InvalidParameter, :state
           end
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

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

    respond_with(R::Image.new(i).generate)
  end

  put '/:id/copy_to' do
    # description 'Update a machine image'
    # param :id, string, :required
    # param :display_name, string, :optional
    # param :description, string, :optional
    raise E::UndefinedImageID if params[:id].nil?
    img = find_image_by_uuid(params[:id])
    raise E::UnknownImage, params[:id] if img.nil?
    if params[:destination] && params[:destination].to_s.size > 0
    else
      raise E::InvalidParameter, :destination
    end

    # TODO: This version only deals with the primary OS image file.
    # It will need to take care for secondary image files.
    bo = img.backup_object

    submit_data = {
      :image => img.to_hash,
      :backup_object => bo.to_hash,
      :destination => params[:destination]
    }
    [:display_name, :description].each { |k|
      submit_data[k] = params[k] if params[k]
    }

    if bo.backup_storage.node_id.nil?
      raise E::InvalidBackupStorage, "Not ready for copy task"
    end

    job = Dcmgr::Messaging.job_queue.submit("backup_storage.copy_to.#{bo.backup_storage.node_id}",
                                            bo.canonical_uuid,
                                            submit_data
                                            )

    respond_with(R::TaskCopyTo.new(job).generate)
  end

  def find_image_by_uuid(uuid)
    item = find_by_uuid(:Image, uuid) || raise(E::UnknownUUIDResource, uuid.to_s)

    if item.is_public == true
      # return immediatly when the public flag is set.
    elsif @account && item.account_id != @account.canonical_uuid
      raise E::UnknownUUIDResoruce, uuid.to_s
    end
    if params[:service_type] && params[:service_type] != item.service_type
      raise E::UnknownUUIDResource, uuid.to_s
    end
    item
  end

end
