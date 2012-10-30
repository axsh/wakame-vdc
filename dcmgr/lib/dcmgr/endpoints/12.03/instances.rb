# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/instance'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/instances' do
  INSTANCE_META_STATE=['alive', 'alive_with_terminated', 'without_terminated'].freeze
  INSTANCE_STATE=['running', 'stopped', 'terminated'].freeze
  INSTANCE_STATE_PARAM_VALUES=(INSTANCE_STATE + INSTANCE_META_STATE).freeze

  # Show list of instances
  # Filter Paramters:
  # start: fixnum, optional
  # limit: fixnum, optional
  # account_id:
  # state: (running|stopped|terminated|alive)
  # created_since, created_until:
  # terminated_since, terminated_until:
  # host_node_id:
  get do
    ds = M::Instance.dataset

    if params[:state]
      ds = case params[:state]
           when *INSTANCE_META_STATE
             case params[:state]
             when 'alive'
               ds.lives
             when 'alive_with_terminated'
               ds.alives_and_termed
             when 'without_terminated'
               ds.without_terminated
             else
               raise E::InvalidParameter, :state
             end
           when *INSTANCE_STATE
             ds.filter(:state=>params[:state])
           else
             raise E::InvalidParameter, :state
           end
    end

    if params[:id]
      uuid = params[:id].split("i-")[1]
      uuid = params[:id] if uuid.nil?
      ds = ds.filter(:uuid.like("%#{uuid}%"))
    end

    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:terminated, ds)

    if params[:host_node_id]
      hn = M::HostNode[params[:host_node_id]] rescue raise(E::InvalidParameter, :host_node_id)
      ds = ds.filter(:host_node_id=>hn.id)
    end

    if params[:service_type]
      Dcmgr.conf.service_types[params[:service_type]] || raise(E::InvalidParameter, :service_type)
      ds = ds.filter(:service_type=>params[:service_type])
    end

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
    end

    collection_respond_with(ds) do |paging_ds|
      R::InstanceCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    i = find_by_uuid(:Instance, params[:id])
    raise E::UnknownInstance, params[:id] if i.nil?

    respond_with(R::Instance.new(i).generate)
  end

  quota 'instance.quota_weight', 'instance.count'
  post do
    # description 'Runs a new VM instance'
    # param :image_id, string, :required
    # param :instance_spec_id, string, :required
    # param :host_node_id, string, :optional
    # param :hostname, string, :optional
    # param :user_data, string, :optional
    # param :security_groups, array, :optional
    # param :vifs, Ruby or JSON hash, :optional, example {"eth0":{"index":"1","network":"nw-demo1","security_groups":"sg-demofgr"},"eth1":{"index":"1","network":"nw-demo2","security_groups":[]}}
    # param :ssh_key_id, string, :optional
    # param :network_id, string, :optional
    # param :ha_enabled, string, :optional
    # param :display_name, string, :optional
    wmi = M::Image[params[:image_id]] || raise(E::InvalidImageID)
    spec = M::InstanceSpec[params[:instance_spec_id]]
    if spec
      params[:hypervisor]   = spec.hypervisor
      params[:cpu_cores]    = spec.cpu_cores
      params[:memory_size]  = spec.memory_size
      params[:quota_weight] = spec.quota_weight
    end

    if params[:hypervisor]
      if M::HostNode.online_nodes.filter(:hypervisor=>params[:hypervisor]).empty?
        raise E::InvalidParameter, :hypervisor
      end
    else
      raise E::InvalidParameter, :hypervisor
    end

    params['cpu_cores'] = params['cpu_cores'].to_i
    if params['cpu_cores'].between?(1, 128)

    else
      raise E::InvalidParameter, :cpu_cores
    end

    params['memory_size'] = params['memory_size'].to_i
    if params['memory_size'].between?(128, 999999)

    else
      raise E::InvalidParameter, :memory_size
    end

    if !M::HostNode.check_domain_capacity?(params['cpu_cores'], params['memory_size'])
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

    if params['vifs'].nil?
      params['vifs'] = {}
    elsif params['vifs'].is_a?(String)
      begin
        params['vifs'] = JSON::load(params['vifs'])
      rescue JSON::ParserError
        raise E::InvalidParameter, 'vifs'
      end
    end

    begin
      Dcmgr::Scheduler::Network.check_vifs_parameter_format(params['vifs'])
    rescue Dcmgr::Scheduler::NetworkSchedulingError
      raise E::InvalidParameter, 'vifs'
    end

    # params is a Mash object. so coverts to raw Hash object.
    instance = M::Instance.entry_new(@account, wmi, @params.dup) do |i|
      i.hypervisor = params[:hypervisor]
      i.cpu_cores = params[:cpu_cores]
      i.memory_size = params[:memory_size]
      i.quota_weight = params[:quota_weight] || 0.0

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

      if params[:service_type]
        i.service_type = params[:service_type]
      end

      if params[:display_name]
        i.display_name = params[:display_name]
      end
    end
    instance.save

    instance.state = :scheduling
    instance.save

    bo = M::BackupObject[wmi.backup_object_id] || raise("Unknown backup object: #{wmi.backup_object_id}")

    case wmi.boot_dev_type
    when M::Image::BOOT_DEV_SAN
      # create new volume from backup object.

      if !M::StorageNode.check_domain_capacity?(bo.size)
        raise E::OutOfDiskSpace
      end

      vol = M::Volume.entry_new(@account, bo.size, params.to_hash) do |v|
        v.backup_object_id = bo.canonical_uuid
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

    on_after_commit do
      Dcmgr.messaging.submit("scheduler",
                             'schedule_instance', instance.canonical_uuid)
    end

    # retrieve latest instance data.
    # if not, security_groups value is empty.
    instance = find_by_uuid(:Instance, instance.canonical_uuid)

    respond_with(R::Instance.new(instance).generate)
  end

  delete '/:id' do
    # description 'Shutdown the instance'
    i = find_by_uuid(:Instance, params[:id])

    case i.state
    when 'stopped'
      # just destroy the record.
      i.destroy
    when 'terminated', 'scheduling'
      raise E::InvalidInstanceState, i.state
    else
      on_after_commit do
        Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'terminate', i.canonical_uuid)
      end
    end
    respond_with([i.canonical_uuid])
  end

  put '/:id/reboot' do
    # description 'Reboots the instance'
    i = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, i.state if i.state != 'running'

    on_after_commit do
      Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'reboot', i.canonical_uuid)
    end
    respond_with([i.canonical_uuid])
  end

  put '/:id/stop' do
    # description 'Stop the instance'
    i = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, i.state if i.state != 'running'

    # relase IpLease from nic.
    i.nic.each { |nic|
      nic.release_ip_lease
    }

    on_after_commit do
      Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'stop', i.canonical_uuid)
    end
    respond_with([i.canonical_uuid])
  end

  put '/:id/start' do
    # description 'Restart the instance'
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state if instance.state != 'stopped'
    instance.state = :scheduling
    instance.save

    on_after_commit do
      Dcmgr.messaging.submit("scheduler", 'schedule_start_instance', instance.canonical_uuid)
    end
    respond_with([instance.canonical_uuid])
  end

  put '/:id' do
    # description 'Updates the security groups an instance is in'
    # param :id, string, :required
    # param :security_groups, array, :optional
    # param :display_name, :string, :optional
    raise E::UndefinedInstanceID if params[:id].nil?

    instance = find_by_uuid(:Instance, params[:id])
    raise E::UnknownInstance if instance.nil?

    if params[:security_groups].is_a?(Array) || params[:security_groups].is_a?(String)
      security_group_uuids = params[:security_groups]
      security_group_uuids = [security_group_uuids] if security_group_uuids.is_a?(String)

      groups = security_group_uuids.map {|group_id| find_by_uuid(:SecurityGroup, group_id)}
      # Remove old security groups
      instance.nic.each { |vnic|
        vnic.security_groups_dataset.each { |group|
          unless security_group_uuids.member?(group.canonical_uuid)
            vnic.remove_security_group(group)
            on_after_commit do
              Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_left",:args=>[vnic.canonical_uuid])
              Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/left_group",:args=>[group.canonical_uuid])
            end
          end
        }
      }

      # Add new security groups
      current_group_ids = instance.nic.first.security_groups_dataset.map {|g| g.canonical_uuid}
      groups.each { |group|
        unless current_group_ids.member?(group.canonical_uuid)
          instance.nic.each { |vnic|
            vnic.add_security_group(group)
            on_after_commit do
              Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_joined",:args=>[vnic.canonical_uuid])
              Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/joined_group",:args=>[group.canonical_uuid])
            end
          }
        end
      }
    end

    instance.display_name = params[:display_name ] if params[:display_name]
    instance.save_changes

    respond_with(R::Instance.new(instance).generate)
  end

  # Create image backup from the alive instance.
  quota 'backup_object.size_mb', 'backup_object.count', 'image.count', 'instance.backup_operations_per_hour'
  put '/:id/backup' do
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state unless ['halted'].member?(instance.state)

    bkst_uuid = params[:backup_storage_id] || Dcmgr.conf.service_types[instance.service_type].backup_storage_id
    bkst = M::BackupStorage[bkst_uuid] || raise(E::UnknownBackupStorage, bkst_uuid)

    bo = instance.image.backup_object.entry_clone do |i|
      [:display_name, :description].each { |k|
        if params[k]
          i[k] = params[k]
        end
      }

      i.state = :pending
      i.account_id = @account.canonical_uuid
    end
    image = instance.image.entry_clone do |i|
      [:display_name, :description, :is_public, :is_cacheable].each { |k|
        if params[k]
          i[k] = params[k]
        end
      }

      i.account_id = @account.canonical_uuid
      i.backup_object_id = bo.canonical_uuid
      i.state = :pending
    end

    on_after_commit do
      Dcmgr.messaging.submit("local-store-handle.#{instance.host_node.node_id}", 'backup_image',
                             instance.canonical_uuid, bo.canonical_uuid, image.canonical_uuid)
    end
    respond_with({:instance_id=>instance.canonical_uuid,
                   :backup_object_id => bo.canonical_uuid,
                   :image_id => image.canonical_uuid,
                 })
  end

  # Halt the running instance.
  put '/:id/poweroff' do
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state unless ['running'].member?(instance.state)

    instance.state = :halting
    instance.save

    on_after_commit do
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'poweroff',
                             instance.canonical_uuid)
    end
    respond_with({:instance_id=>instance.canonical_uuid,
                 })
  end

  # Restart the instance from halted state.
  put '/:id/poweron' do
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state unless ['halted'].member?(instance.state)

    instance.state = :starting
    instance.save

    on_after_commit do
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'poweron',
                             instance.canonical_uuid)
    end
    respond_with({:instance_id=>instance.canonical_uuid,
                 })
  end
end
