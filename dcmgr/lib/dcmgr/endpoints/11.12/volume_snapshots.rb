# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/volume_snapshots' do
  get do
    # description 'Show lists of the volume_snapshots'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:VolumeSnapshot, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
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
    response_to(vs.to_api_document)
  end

  post do
    # description 'Create a new volume snapshot'
    # params volume_id, string, required
    # params detination, string, required
    # params storage_pool_id, string, optional
    M::Volume.lock!
    raise E::UndefinedVolumeID if params[:volume_id].nil?

    v = find_by_uuid(:Volume, params[:volume_id])
    raise E::UnknownVolume if v.nil?
    raise E::InvalidVolumeState unless v.ready_to_take_snapshot?
    vs = v.create_snapshot(@account.canonical_uuid)
    sp = vs.storage_node
    destination_key = Dcmgr::StorageService.destination_key(@account.canonical_uuid, params[:destination], sp.snapshot_base_path, vs.snapshot_filename)
    vs.update_destination_key(@account.canonical_uuid, destination_key)

    res = vs.to_api_document
    repository_address = Dcmgr::StorageService.repository_address(destination_key)

    commit_transaction
    Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid, repository_address)

    response_to(res)
  end

  delete '/:id' do
    # description 'Delete the volume snapshot'
    # params id, string, required
    M::VolumeSnapshot.lock!
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

    repository_address = Dcmgr::StorageService.repository_address(destination_key)

    commit_transaction
    Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid, repository_address)

    response_to([vs.canonical_uuid])
  end

end

