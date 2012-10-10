# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/volumes' do
  get do
    # description 'Show lists of the volume'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:Volume, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  get '/:id' do
    # description 'Show the volume status'
    # params id, string, required
    volume_id = params[:id]
    raise E::UndefinedVolumeID if volume_id.nil?
    v = find_by_uuid(:Volume, volume_id)
    response_to(v.to_api_document)
  end

  post do
    # description 'Create the new volume'
    # params volume_size, string, required
    # params snapshot_id, string, optional
    # params storage_pool_id, string, optional
    M::Volume.lock!
    sp = vs = vol = nil
    # input parameter validation
    if params[:snapshot_id]
      vs = find_volume_snapshot(params[:snapshot_id])
    elsif params[:volume_size]
      if !(Dcmgr.conf.create_volume_max_size.to_i >= params[:volume_size].to_i) ||
          !(params[:volume_size].to_i >= Dcmgr.conf.create_volume_min_size.to_i)
        raise E::InvalidVolumeSize
      end
      if params[:storage_pool_id]
        sp = find_by_uuid(:StorageNode, params[:storage_pool_id])
        raise E::UnknownStorageNode if sp.nil?
      end
    else
      raise E::UndefinedRequiredParameter
    end

    volume_size = (vs ? vs.size : params[:volume_size].to_i)

    if !M::StorageNode.check_domain_capacity?(volume_size)
      raise E::OutOfDiskSpace
    end

    # params is a Mash object. so coverts to raw Hash object.
    vol = M::Volume.entry_new(@account, volume_size, params.to_hash) do |v|
      if vs
        v.snapshot_id = vs.canonical_uuid
      end
    end
    vol.save

    if sp.nil?
      # going to storage node scheduling mode.
      vol.state = :scheduling
      vol.save

      commit_transaction

      Dcmgr.messaging.submit("scheduler", 'schedule_volume', vol.canonical_uuid)
    else
      begin
        vol.storage_node = sp
        vol.save
      rescue M::Volume::CapacityError => e
        logger.error(e)
        raise E::OutOfDiskSpace
      end

      vol.state = :pending
      vol.save

      commit_transaction

      repository_address = nil
      if vol.snapshot
        repository_address = Dcmgr::StorageService.repository_address(vol.snapshot.destination_key)
      end

      Dcmgr.messaging.submit("sta-handle.#{vol.storage_node.node_id}", 'create_volume', vol.canonical_uuid, repository_address)
    end

    response_to(vol.to_api_document)
  end

  delete '/:id' do
    # description 'Delete the volume'
    # params id, string, required
    volume_id = params[:id]
    raise E::UndefinedVolumeID if volume_id.nil?

    vol = find_by_uuid(:Volume, volume_id)
    raise E::UnknownVolume if vol.nil?
    raise E::InvalidVolumeState, "#{vol.state}" unless vol.state == "available"


    begin
      v  = M::Volume.delete_volume(@account.canonical_uuid, volume_id)
    rescue M::Volume::RequestError => e
      logger.error(e)
      raise E::InvalidDeleteRequest
    end
    raise E::UnknownVolume if v.nil?

    commit_transaction
    Dcmgr.messaging.submit("sta-handle.#{v.storage_node.node_id}", 'delete_volume', v.canonical_uuid)
    response_to([v.canonical_uuid])
  end

  put '/:id/attach' do
    # description 'Attachd the volume'
    # params id, string, required
    # params instance_id, string, required
    raise E::UndefinedInstanceID if params[:instance_id].nil?
    raise E::UndefinedVolumeID if params[:id].nil?

    i = find_by_uuid(:Instance, params[:instance_id])
    raise E::UnknownInstance if i.nil?
    raise E::InvalidInstanceState unless i.live? && i.state == 'running'

    v = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume if v.nil?
    raise E::AttachVolumeFailure, "Volume is attached to running instance." if v.instance

    v.instance = i
    v.save

    res = v.to_api_document

    commit_transaction
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)

    response_to(res)
  end

  get '/:id/detach' do
    # description 'Detachd the volume'
    # params id, string, required
    raise E::UndefinedVolumeID if params[:id].nil?

    v = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume if v.nil?
    raise E::DetachVolumeFailure, "Volume is not attached to any instance." if v.instance.nil?
    # the volume as the boot device can not be detached.
    raise E::DetachVolumeFailure, "boot device can not be detached" if v.boot_dev == 1
    i = v.instance
    raise E::InvalidInstanceState unless i.live? && i.state == 'running'
    res = v.to_api_document

    commit_transaction
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'detach', i.canonical_uuid, v.canonical_uuid)

    response_to(res)
  end

end

