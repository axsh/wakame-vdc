# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/volume'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/volumes' do
  VOLUME_META_STATE=['alive'].freeze
  VOLUME_STATE=['available', 'attached', 'deleted'].freeze
  VOLUME_STATE_PARAM_VALUES=(VOLUME_STATE + VOLUME_META_STATE).freeze

  # Show list of volumes
  # params start, fixnum, optional
  # params limit, fixnum, optional
  get do
    ds = M::Volume.dataset
    if params[:state]
      ds = if VOLUME_META_STATE.member?(params[:state])
             case params[:state]
             when 'alive'
               ds.lives
             else
               raise E::InvalidParameter, :state
             end
           elsif VOLUME_STATE.member?(params[:state])
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
      hn = M::StorageNode[params[:storage_node_id]] rescue raise(E::InvalidParameter, :storage_node_id)
      ds = ds.filter(:storage_node_id=>hn.id)
    end
    
    collection_respond_with(ds) do |paging_ds|
      R::VolumeCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description 'Show the volume status'
    # params id, string, required
    volume_id = params[:id]
    raise E::UndefinedVolumeID if volume_id.nil?
    v = find_by_uuid(:Volume, volume_id)
    raise E::UnknownVolume, params[:id] if v.nil?
    respond_with(R::Volume.new(v).generate)
  end
  
  post do
    # description 'Create the new volume'
    # params volume_size, string, required
    # params snapshot_id, string, optional
    # params storage_pool_id, string, optional
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
        raise E::StorageNodeNotPermitted if sp.account_id != @account.canonical_uuid
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

    respond_with(R::Volume.new(vol).generate)
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
    respond_with([v.canonical_uuid])
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
    commit_transaction
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)

    respond_with(R::Volume.new(v).generate)
  end

  put '/:id/detach' do
    # description 'Detach the volume'
    # params id, string, required
    raise E::UndefinedVolumeID if params[:id].nil?

    v = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume if v.nil?
    raise E::DetachVolumeFailure, "Volume is not attached to any instance." if v.instance.nil?
    # the volume as the boot device can not be detached.
    raise E::DetachVolumeFailure, "boot device can not be detached" if v.boot_dev == 1
    i = v.instance
    raise E::InvalidInstanceState unless i.live? && i.state == 'running'
    commit_transaction
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'detach', i.canonical_uuid, v.canonical_uuid)
    respond_with(R::Volume.new(v).generate)
  end

end
