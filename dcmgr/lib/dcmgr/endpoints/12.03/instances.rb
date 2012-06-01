# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/instance'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/instances' do
  INSTANCE_META_STATE=['alive', 'alive_and_terminated'].freeze
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
      ds = if INSTANCE_META_STATE.member?(params[:state])
             case params[:state]
             when 'alive'
               ds.lives
             else
               raise E::InvalidParameter, :state
             end
           elsif INSTANCE_STATE.member?(params[:state])
             ds.filter(:state=>params[:state])
           else
             raise E::InvalidParameter, :state
           end
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
    # param :display_name, string, :optional
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

    commit_transaction
    Dcmgr.messaging.submit("scheduler",
                           'schedule_instance', instance.canonical_uuid)

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
      Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'terminate', i.canonical_uuid)
    end
    respond_with([i.canonical_uuid])
  end

  put '/:id/reboot' do
    # description 'Reboots the instance'
    i = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, i.state if i.state != 'running'
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'reboot', i.canonical_uuid)
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
    
    Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'stop', i.canonical_uuid)
    respond_with([i.canonical_uuid])
  end

  put '/:id/start' do
    # description 'Restart the instance'
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state if instance.state != 'stopped'
    instance.state = :scheduling
    instance.save

    commit_transaction
    Dcmgr.messaging.submit("scheduler", 'schedule_start_instance', instance.canonical_uuid)
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
            Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_left",:args=>[vnic.canonical_uuid])
            Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/left_group",:args=>[group.canonical_uuid])
          end
        }
      }
      
      # Add new security groups
      current_group_ids = instance.nic.first.security_groups_dataset.map {|g| g.canonical_uuid}
      groups.each { |group|
        unless current_group_ids.member?(group.canonical_uuid)
          instance.nic.each { |vnic|
            vnic.add_security_group(group)
            Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_joined",:args=>[vnic.canonical_uuid])
            Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/joined_group",:args=>[group.canonical_uuid])
          }
        end
      }
    end
    
    instance.display_name = params[:display_name ] if params[:display_name]
    instance.save_changes

    commit_transaction
    respond_with(R::Instance.new(instance).generate)
  end
end
