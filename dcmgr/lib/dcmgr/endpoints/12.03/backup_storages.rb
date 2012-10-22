# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/backup_storage'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/backup_storages' do
  get do
    # description 'Show lists of the volume_snapshots'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    ds = M::BackupStorage.dataset

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
    end

    if params[:storage_type]
      ds = ds.filter(:storage_type=>params[:storage_type])
    end

    collection_respond_with(ds) do |paging_ds|
      R::BackupStorageCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    bkst = find_by_uuid(:BackupStorage, params[:id])
    raise E::UnknownBackupStorage, params[:id] if bkst.nil?
    respond_with(R::BackupStorage.new(bkst).generate)
  end

  # Register new backup storage
  post do
    bkst = M::BackupStorage.create(:storage_type=>params[:storage_type],
                                   :base_uri => params[:base_uri],
                                   ) do |i|
      if params[:description]
        i.description = params[:description]
      end

      if params[:display_name]
        i.display_name = params[:display_name]
      end

      if params[:uuid]
        i.uuid = params[:uuid]
      end
    end

    respond_with(R::BackupStorage.new(bkst).generate)
  end

  put '/:id' do
    bkst = find_by_uuid(:BackupStorage, params[:id])
    bkst.description = params[:description] if params[:description]
    bkst.display_name = params[:display_name] if params[:display_name]
    bkst.uuid = params[:uuid] if params[:uuid]
    bkst.storage_type = params[:storage_type] if params[:storage_type]
    bkst.base_uri = params[:base_uri] if params[:base_uri]
    bkst.save_changes

    respond_with([bkst.canonical_uuid])
  end

  delete '/:id' do
    bkst = find_by_uuid(:BackupStorage, params[:id])
    bkst.destroy

    respond_with([bkst.canonical_uuid])
  end
end
