# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/volume_snapshot'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/volume_snapshots' do
  VOLUME_SNAPSHOT_META_STATE=['alive'].freeze
  VOLUME_SNAPSHOT_STATE=['available', 'deleted'].freeze
  VOLUME_SNAPSHOT_STATE_PARAM_VALUES=(VOLUME_SNAPSHOT_STATE + VOLUME_SNAPSHOT_META_STATE).freeze
  get do
    # description 'Show lists of the volume_snapshots'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    ds = M::VolumeSnapshot.dataset
    if params[:state]
      ds = if VOLUME_SNAPSHOT_META_STATE.member?(params[:state])
             case params[:state]
             when 'alive'
               ds.alives
             else
               raise E::InvalidParameter, :state
             end
           elsif VOLUME_SNAPSHOT_STATE.member?(params[:state])
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

    if params[:storage_node_id]
      sn = find_by_uuid(M::StorageNode, params[:storage_node_id])
      raise UnknownStorageNode, params[:storage_node_id] if sn.nil?

      ds = ds.filter(:storage_node_id=>sn.id)
    end

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
    end

    collection_respond_with(ds) do |paging_ds|
      R::VolumeSnapshotCollection.new(paging_ds).generate
    end
  end

  get '/upload_destination' do
    c = Dcmgr::StorageService::snapshot_repository_config.dup
    tmp = c['local']
    c.delete('local')
    results = {}
    results = c.collect {|item| {
        :destination_id => item[0],
        :destination_name => item[1]["display_name"]
      }
    }
    results.unshift({
                      :destination_id => 'local',
                      :destination_name => tmp['display_name']
                    })
    response_to([{:results => results}])
  end

  get '/:id' do
    # description 'Show the volume status'
    # params id, string, required
    snapshot_id = params[:id]
    raise E::UndefinedVolumeSnapshotID if snapshot_id.nil?
    vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
    raise E::UnknownVolumeSnapshot, snapshot_id if vs.nil?
    respond_with(R::VolumeSnapshot.new(vs).generate)
  end

  post do
    # description 'Create a new volume snapshot'
    # params volume_id, string, required
    # params detination, string, required
    # params storage_pool_id, string, optional
    # params display_name, string, optional
    raise E::UndefinedVolumeID if params[:volume_id].nil?

    v = find_by_uuid(:Volume, params[:volume_id])
    raise E::UnknownVolume if v.nil?
    raise E::InvalidVolumeState unless v.ready_to_take_snapshot?
    vs = v.create_snapshot(@account.canonical_uuid)
    sp = vs.storage_node
    destination_key = Dcmgr::StorageService.destination_key(@account.canonical_uuid, params[:destination], sp.snapshot_base_path, vs.snapshot_filename)
    vs.update_destination_key(@account.canonical_uuid, destination_key)
    vs.update_snapshot_display_name(params[:display_name]) if params[:display_name]
    commit_transaction

    repository_address = Dcmgr::StorageService.repository_address(destination_key)
    Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid, repository_address)
    respond_with(R::VolumeSnapshot.new(vs).generate)
  end

  delete '/:id' do
    # description 'Delete the volume snapshot'
    # params id, string, required
    snapshot_id = params[:id]
    raise E::UndefindVolumeSnapshotID if snapshot_id.nil?

    v = find_by_uuid(:VolumeSnapshot, snapshot_id)
    raise E::UnknownVolumeSnapshot if v.nil?
    raise E::InvalidVolumeState unless v.state == "available"

    destination_key = v.destination_key

    begin
      vs  = M::VolumeSnapshot.delete_snapshot(@account.canonical_uuid, snapshot_id)
    rescue M::VolumeSnapshot::RequestError => e
      logger.error(e)
      raise E::InvalidDeleteRequest
    end
    raise E::UnknownVolumeSnapshot if vs.nil?
    sp = vs.storage_node

    commit_transaction

    repository_address = Dcmgr::StorageService.repository_address(destination_key)
    Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid, repository_address)
    respond_with([vs.canonical_uuid])
  end

  put '/:id' do
    # description "Update volume snapshot information"
    # params id, string, required
    # params display_name, string, optional
    raise E::UndefindVolumeSnapshotID if params[:id].nil?

    vs = find_by_uuid(:VolumeSnapshot, params[:id])
    raise E::UnknownVolumeSnapshot if vs.nil?

    vs.update_snapshot_display_name(params[:display_name]) if params[:display_name]
    commit_transaction
    respond_with(R::VolumeSnapshot.new(vs).generate)
  end
end
