# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/instances' do
  get do
    # description 'Show list of instances'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:Instance, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  post do
    # description 'Runs a new VM instance'
    # param :image_id, string, :required
    # param :instance_spec_id, string, :required
    # param :host_node_id, string, :optional
    # param :hostname, string, :optional
    # param :user_data, string, :optional
    # param :security_groups, array, :optional
    # param :ssh_key_id, string, :optional
    # param :network_id, string, :optional
    # param :ha_enabled, string, :optional
    M::Instance.lock!

    wmi = M::Image[params[:image_id]] || raise(E::InvalidImageID)
    spec = M::InstanceSpec[params[:instance_spec_id]] || raise(E::InvalidInstanceSpec)

    if !M::HostNode.check_domain_capacity?(spec.cpu_cores, spec.memory_size)
      raise E::OutOfHostCapacity
    end

    # TODO:
    #  "host_id" and "host_pool_id" will be obsolete.
    #  They are used in lib/dcmgr/scheduler/host_node/specify_node.rb.
    if params[:host_id] || params[:host_pool_id] || params[:host_node_id]
      host_node_id = params[:host_id] || params[:host_pool_id] || params[:host_node_id]
      host_node = M::HostNode[host_node_id]
      raise E::UnknownHostNode, "#{host_node_id}" if host_node.nil?
      raise E::InvalidHostNodeID, "#{host_node_id}" if host_node.status != 'online'
    end

    # params is a Mash object. so coverts to raw Hash object.
    instance = M::Instance.entry_new(@account, wmi, spec, params.to_hash) do |i|
      # Set common parameters from user's request.
      i.user_data = params[:user_data] || ''
      # set only when not nil as the table column has not null
      # condition.
      if params[:hostname]
        if M::Instance::ValidationMethods.hostname_uniqueness(@account.canonical_uuid,
                                                              params[:hostname])
          i.hostname = params[:hostname]
        else
          raise E::DuplicateHostname
        end
      end

      if params[:ssh_key_id]
        ssh_key_pair = M::SshKeyPair[params[:ssh_key_id]]

        if ssh_key_pair.nil?
          raise E::UnknownSshKeyPair, "#{params[:ssh_key_id]}"
        else
          i.set_ssh_key_pair(ssh_key_pair)
        end
      end

      if params[:ha_enabled] == 'true'
        i.ha_enabled = 1
      end
    end
    instance.save

    instance.state = :scheduling
    instance.save

    case wmi.boot_dev_type
    when M::Image::BOOT_DEV_SAN
      # create new volume from snapshot.
      snapshot_id = wmi.source[:snapshot_id]
      vs = find_volume_snapshot(snapshot_id)

      if !M::StorageNode.check_domain_capacity?(vs.size)
        raise E::OutOfDiskSpace
      end

      vol = M::Volume.entry_new(@account, vs.size, params.to_hash) do |v|
        if vs
          v.snapshot_id = vs.canonical_uuid
        end
        v.boot_dev = 1
      end
      # assign instance -> volume
      vol.instance = instance
      vol.state = :scheduling
      vol.save

    when M::Image::BOOT_DEV_LOCAL
    else
      raise "Unknown boot type"
    end

    res = instance.to_api_document

    commit_transaction
    Dcmgr.messaging.submit("scheduler",
                           'schedule_instance', instance.canonical_uuid)
    response_to(res)
  end

  get '/:id' do
    #param :account_id, :string, :optional
    i = find_by_uuid(:Instance, params[:id])
    raise E::UnknownInstance if i.nil?

    response_to(i.to_api_document)
  end

  delete '/:id' do
    # description 'Shutdown the instance'
    i = find_by_uuid(:Instance, params[:id])
    if examine_owner(i)
    else
      raise E::OperationNotPermitted
    end

    case i.state
    when 'stopped'
      # just destroy the record.
      i.destroy
    when 'terminated', 'scheduling'
      raise E::InvalidInstanceState, i.state
    else
      Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'terminate', i.canonical_uuid)
    end
    response_to([i.canonical_uuid])
  end

  put '/:id/reboot' do
    # description 'Reboots the instance'
    i = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, i.state if i.state != 'running'
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'reboot', i.canonical_uuid)
    response_to([i.canonical_uuid])
  end

  put '/:id/stop' do
    # description 'Stop the instance'
    i = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, i.state if i.state != 'running'

    # relase IpLease from nic.
    i.nic.each { |nic|
      nic.release_ip_lease
    }

    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'stop', i.canonical_uuid)
    response_to([i.canonical_uuid])
  end

  put '/:id/start' do
    # description 'Restart the instance'
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state if instance.state != 'stopped'
    instance.state = :scheduling
    instance.save

    commit_transaction
    Dcmgr.messaging.submit("scheduler", 'schedule_start_instance', instance.canonical_uuid)
    response_to([instance.canonical_uuid])
  end
end
