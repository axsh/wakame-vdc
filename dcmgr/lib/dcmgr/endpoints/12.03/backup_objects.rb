# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/backup_object'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/backup_objects' do
  BACKUP_OBJECT_META_STATE=['alive', 'alive_with_deleted'].freeze
  BACKUP_OBJECT_STATE=['available', 'deleted'].freeze
  BACKUP_OBJECT_STATE_PARAM_VALUES=(BACKUP_OBJECT_STATE + BACKUP_OBJECT_META_STATE).freeze
  get do
    ds = M::BackupObject.dataset
    if params[:state]
      ds = case params[:state]
           when *BACKUP_OBJECT_META_STATE
             case params[:state]
             when 'alive'
               ds.alives
             when 'alive_with_deleted'
               ds.alives_and_deleted
             else
               raise E::InvalidParameter, :state
             end
           when *BACKUP_OBJECT_STATE
             ds.filter(:state=>params[:state])
           else
             raise E::InvalidParameter, :state
           end
    end

    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    if params[:backup_storage_id]
      bs = find_by_uuid(M::BackupStorage, params[:backup_storage_id])
      raise UnknownBackupStorage, params[:backup_storage_id] if bs.nil?

      ds = ds.filter(:backup_storage_id=>bs.id)
    end

    if params[:service_type]
      Dcmgr.conf.service_types[params[:service_type]] || raise(E::InvalidParameter, :service_type)
      ds = ds.filter(:service_type=>params[:service_type])
    end

    collection_respond_with(ds) do |paging_ds|
      R::BackupObjectCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    raise E::UndefinedBackupObjectID if params[:id].nil?
    bo = find_by_uuid(:BackupObject, params[:id])
    raise E::UnknownBackupObject, params[:id] if bo.nil?
    respond_with(R::BackupObject.new(bo).generate)
  end

  quota 'backup_object.size_mb' do
    request_amount do
      params[:size].to_i / (1024 * 1024)
    end
  end
  quota 'backup_object.count'
  post do
    bkst = M::BackupStorage[params[:backup_storage_id]] || raise(E::UnknownBackupStorage, params[:backup_storage_id])
    bo = M::BackupObject.create(:backup_storage_id=>bkst.id,
                                :account_id => params[:account_id],
                                :object_key => params[:object_key],
                                :size => params[:size],
                                :checksum => params[:checksum],
                                ) do |i|
      # optional parameters
      [:allocation_size, :service_type, :display_name, :description, :state].each { |k|
        if params[k]
          i[k] = params[k]
        end
      }
    end

    respond_with(R::BackupObject.new(bo).generate)
  end

  put '/:id' do
    bo = find_by_uuid(:BackupObject, params[:id])
    [:service_type, :display_name, :description].each { |k|
      if params[k]
        bo[k] = params[k]
      end
    }
    bo.save_changes

    respond_with(R::BackupObject.new(bo).generate)
  end

  # Register copy_to task
  put '/:id/copy_to' do
    bo = find_by_uuid(:BackupObject, params[:id])
    if params[:destination] && params[:destination].to_s.size > 0
    else
      raise E::InvalidParameter, :destination
    end

    if bo.backup_storage.node.nil?
      raise E::InvalidBackupStorage, "Not ready for copy_to task."
    end

    Dcmgr::Messaging.job_queue.submit("backup_storage.copy_to.#{bo.backup_storage.node_id}",
                                      bo.canonical_uuid,
                                      {:destination=>params[:destination]}
                                      )

    respond_with(R::BackupObject.new(bo).generate)
  end

  delete '/:id' do
    raise E::UndefindBackupObjectID if params[:id].nil?

    bo = find_by_uuid(:BackupObject, params[:id])
    raise E::UnknownBackupObject, params[:id] if bo.nil?
    raise E::InvalidBackupObjectState, params[:id] unless bo.state == "available"

    begin
      bo.destroy
    rescue M::BackupObject::RequestError => e
      logger.error(e)
      raise E::InvalidDeleteRequest
    end

    respond_with([bo.canonical_uuid])
  end
end
