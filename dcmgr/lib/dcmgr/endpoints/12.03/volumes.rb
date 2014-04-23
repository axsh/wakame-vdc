# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/volume'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/volumes' do
  VOLUME_META_STATE=['alive', 'alive_with_deleted'].freeze
  VOLUME_STATE=['available', 'attached', 'deleted'].freeze
  VOLUME_STATE_PARAM_VALUES=(VOLUME_STATE + VOLUME_META_STATE).freeze

  # Show list of volumes
  # params start, fixnum, optional
  # params limit, fixnum, optional
  get do
    ds = M::Volume.dataset
    if params[:state]
      ds = case params[:state]
           when *VOLUME_META_STATE
             case params[:state]
             when 'alive'
               ds.lives
             when 'alive_with_deleted'
               ds.alives_and_deleted
             else
               raise E::InvalidParameter, :state
             end
           when *VOLUME_STATE
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

    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:service_type=>params[:service_type])
    end

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
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

  quota('volume.size_mb') do
    request_amount do
      if params[:backup_object_id]
        bo = find_by_uuid(:BackupObject, params[:backup_object_id])
        return bo.size / (1024 * 1024)
      elsif params[:volume_size]
        # volume_size uses MB unit.
        return params[:volume_size]
      end
    end
  end
  quota 'volume.count'
  post do
    sp = vs = vol = nil
    # input parameter validation
    if !params[:backup_object_id].blank?
      bo = vs = find_by_uuid(:BackupObject, params[:backup_object_id])
    elsif !params[:volume_size].blank?
      if !(Dcmgr.conf.create_volume_max_size.to_i >= params[:volume_size].to_i) ||
          !(params[:volume_size].to_i >= Dcmgr.conf.create_volume_min_size.to_i)
        raise E::InvalidVolumeSize, params[:volume_size]
      end
    else
      raise E::UndefinedRequiredParameter
    end

    # TODO: storage node group assignment
    if !params[:storage_node_id].blank?
      sp = find_by_uuid(:StorageNode, params[:storage_node_id])
      raise E::UnknownStorageNode, params[:storage_node_id] if sp.nil?
    end

    volume_size = (bo ? bo.size : params[:volume_size].to_i * (1024 * 1024))

    if sp
      # TODO: check only for storage node from params[:storage_node_id]
    elsif !M::StorageNode.check_domain_capacity?(volume_size)
      raise E::OutOfDiskSpace
    end

    # params is a Mash object. so coverts to raw Hash object.
    vol = M::Volume.entry_new(@account, volume_size, @params.dup) do |v|
      if bo
        v.backup_object_id = vs.canonical_uuid
      end

      if !params[:service_type].blank?
        validate_service_type(params[:service_type])
        v.service_type = params[:service_type]
      end

      if !params[:display_name].blank?
        v.display_name = params[:display_name]
      end
    end
    vol.save

    if sp.nil?
      # going to storage node scheduling mode.
      vol.state = :scheduling

      on_after_commit do
        Dcmgr.messaging.submit("scheduler", 'schedule_volume', vol.canonical_uuid)
      end
    else
      begin
        sp.associate_volume(vol)
      rescue M::Volume::CapacityError => e
        logger.error(e)
        raise E::OutOfDiskSpace
      end

      vol.state = :pending

      on_after_commit do
        Dcmgr.messaging.submit("sta-handle.#{vol.storage_node.node_id}", 'create_volume', vol.canonical_uuid)
      end
    end
    vol.save_changes

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
      vol.entry_delete
    rescue M::Volume::RequestError => e
      logger.error(e)
      raise E::InvalidDeleteRequest
    end

    on_after_commit do
      Dcmgr.messaging.submit("sta-handle.#{vol.storage_node.node_id}", 'delete_volume', vol.canonical_uuid)
    end
    respond_with([vol.canonical_uuid])
  end

  put '/:id/attach' do
    # description 'Attachd the volume'
    # params id, string, required
    # params instance_id, string, required
    raise E::UndefinedInstanceID if params[:instance_id].blank?
    raise E::UndefinedVolumeID if params[:id].blank?

    i = find_by_uuid(:Instance, params[:instance_id])
    raise E::UnknownInstance, params[:instance_id] if i.nil?
    raise E::InvalidInstanceState unless i.live? && ['running', 'halted'].member?(i.state)

    v = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume, params[:id] if v.nil?
    if v.instance && v.state == C::Volume::STATE_ATTACHED
      raise E::AttachVolumeFailure, "Volume is attached to running instance."
    end

    guest_device_name = nil
    if !params['guest_device_name'].blank?
      guest_device_name = params['guest_device_name']
    end

    v.attach_to_instance(i, guest_device_name)

    if i.state == 'running'
      # hot add/attach
      on_after_commit do
        Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)
      end
    end

    respond_with(R::Volume.new(v).generate)
  end

  put '/:id/detach' do
    # description 'Detach the volume'
    # params id, string, required
    raise E::UndefinedVolumeID if params[:id].nil?

    v = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume if v.nil?
    if v.instance.nil?
      raise E::DetachVolumeFailure, "Volume is not attached to any instance."
    elsif v.boot_volume?
      # the volume as the boot device can not be detached.
      raise E::DetachVolumeFailure, "boot device can not be detached"
    end
    i = v.instance
    raise E::InvalidInstanceState unless i.live? && ['running', 'halted'].member?(i.state)

    if i.state == 'running'
      # hot remove/detach
      on_after_commit do
        Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'detach', i.canonical_uuid, v.canonical_uuid)
      end
    end

    respond_with(R::Volume.new(v).generate)
  end

  # Create new backup
  quota 'backup_object.size_mb' do
    request_amount do
      v = find_by_uuid(:Volume, params[:id])
      if v
        return v.size / (1024 * 1024)
      end
    end
  end
  quota 'backup_object.count'
  put '/:id/backup' do
    raise E::UndefinedVolumeID if params[:id].nil?
    @volume = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume, params[:id] if @volume.nil?
    raise E::InvalidVolumeState, params[:id] unless @volume.ready_to_take_snapshot?

    if @volume.instance && !['running', 'halted'].member?(@volume.instance.state.to_s)
      raise E::InvalidInstanceState, @volume.instance.canonical_uuid
    end
    
    bkst = find_target_backup_storage(@volume.service_type)
    
    bo = @volume.create_backup_object(@account) do |b|
      b.state = C::BackupObject::STATE_PENDING
      if bkst
        b.backup_storage = bkst
      end
    end

    on_after_commit do
      if @volume.local_volume?
        instance = @volume.volume_device.instance
        Dcmgr.messaging.submit("local-store-handle.#{instance.host_node.node_id}", 'backup_volume',
                               instance.canonical_uuid, @volume.canonical_uuid, bo.canonical_uuid)
      else
        Dcmgr.messaging.submit("sta-handle.#{@volume.volume_device.storage_node.node_id}", 'backup_volume',
                               @volume.canonical_uuid, bo.canonical_uuid)
      end
    end
    respond_with({:volume_id=>@volume.canonical_uuid,
                   :backup_object_id => bo.canonical_uuid,
                 })
  end

  put '/:id' do
    # description 'Update volume information'
    # params id, string, required
    # params display_name, string, optional
    raise E::UndefinedVolumeID if params[:id].nil?

    v = find_by_uuid(:Volume, params[:id])
    raise E::UnknownVolume if v.nil?

    v.display_name = params[:display_name] if params[:display_name]
    v.save_changes

    respond_with(R::Volume.new(v).generate)
  end
end
