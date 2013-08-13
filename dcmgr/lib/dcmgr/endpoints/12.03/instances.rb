# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/instance'
require 'multi_json'

# To validate ip address syntax in the vifs parameter
require 'ipaddress'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/instances' do
  INSTANCE_META_STATE=['alive', 'alive_with_terminated', 'without_terminated'].freeze
  INSTANCE_STATE=['running', 'stopped', 'terminated'].freeze
  INSTANCE_STATE_PARAM_VALUES=(INSTANCE_STATE + INSTANCE_META_STATE).freeze

  register V1203::Helpers::ResourceLabel
  enable_resource_label(M::Instance)

  def check_network_ip_combo(network_id,ip_addr)
    nw = M::Network[network_id]
    raise E::UnknownNetwork, network_id if nw.nil?

    if ip_addr
      raise E::InvalidIPAddress, ip_addr unless IPAddress.valid_ipv4?(ip_addr)

      leaseaddr = IPAddress(ip_addr)
      raise E::DuplicateIPAddress, ip_addr unless M::IpLease.filter(:ipv4 => leaseaddr.to_i).empty?

      segment = IPAddress("#{nw.ipv4_network}/#{nw.prefix}")
      raise E::IPAddressNotInSegment, ip_addr unless segment.include?(leaseaddr)

      raise E::IpNotInDhcpRange, ip_addr unless nw.exists_in_dhcp_range?(leaseaddr)
    end
  end

  # monitoring.items nested parameters are accepted only at POST
  # /instances call. It is unable from PUT /instances.
  # Further modifications can be done from "/instances/i-xxxxx/monitoring"
  # API namespace.
  def insert_monitoring_items(instance)
    # monitoring parameter is optional.
    if params['monitoring'].nil?
      return false
    elsif !params['monitoring'].is_a?(Hash)
      raise E::InvalidParameter, 'monitoring'
    end

    monitoring_params = params['monitoring']

    if monitoring_params.has_key?('items')
      items_param = monitoring_params['items']
      case items_param
      when Array
        items_param.each { |i|
          instance.add_monitor_item(i['title'], i['enabled'], i['params'])
        }
      when Hash
        items_param.each_pair { |k, i|
          instance.add_monitor_item(i['title'], i['enabled'], i['params'])
        }
      else
        raise E::InvalidParameter, "monitoring.items"
      end

      return true
    end
    return false
  end
  
  def set_monitoring_parameters(instance)
    dirty = [false]
    # monitoring parameter is optional.
    if params['monitoring'].nil?
      return false
    elsif !params['monitoring'].is_a?(Hash)
      raise E::InvalidParameter, 'monitoring'
    end

    monitoring_params = params['monitoring']

    # Old instance_monitor_attrs table update
    instance.instance_monitor_attr.enabled = (monitoring_params['enabled'] == 'true')
    if monitoring_params.has_key?('mail_address')
      mail_addrs = monitoring_params['mail_address']
      case mail_addrs
      when "", nil
        # Indicates to clear the recipients.
        instance.instance_monitor_attr.recipients = []
      when Array
        instance.instance_monitor_attr.tap { |o|
          o.recipients = mail_addrs.map {|v| {:mail_address=>v}}
        }
      when Hash
        instance.instance_monitor_attr.tap { |o|
          o.recipients = mail_addrs.map {|k, v| {:mail_address=>v}}
        }
      else
        raise E::InvalidParameter, "monitoring.mail_address"
      end
      instance.instance_monitor_attr.changed_columns << :recipients
    end
    if instance.instance_monitor_attr.modified?
      dirty[0] = true
      instance.instance_monitor_attr.save_changes
    end

    return dirty.any?
  end

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
      ds = ds.filter(:uuid.like("#{uuid}%"))
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

  quota('instance.quota_weight') do
    request_amount do
      params[:quota_weight].to_f
    end
  end
  quota 'instance.count'
  post do
    # description 'Runs a new VM instance'
    # param :image_id, string, :required
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

    # Check vifs parameter values
    is_manual_ip_set=false
    params["vifs"].each { |name,temp|
      mac_addr = temp["mac_addr"]
      if mac_addr
        raise E::InvalidMacAddress, mac_addr if !(mac_addr.size == 12 && mac_addr =~ /^[0-9a-fA-F]{12}$/)
        raise E::DuplicateMacAddress, mac_addr if M::MacLease.is_leased?(mac_addr)

        # Check if this mac address exists in a defined range
        m_vid, m_a = M::MacLease.string_to_ints(mac_addr)
        raise E::MacNotInRange, mac_addr unless M::MacRange.exists_in_any_range?(m_vid,m_a)
      end

      if temp["ipv4_addr"]
        check_network_ip_combo(temp["network"], temp["ipv4_addr"])
        is_manual_ip_set = true
      end

      if temp["nat_ipv4_addr"]
        check_network_ip_combo(temp["nat_network"], temp["nat_ipv4_addr"])
        is_manual_ip_set = true
      end

      [temp["security_groups"]].flatten.select{|s| !s.blank?}.each do |security_group_uuid|
        raise E::UnknownSecurityGroup unless find_by_uuid(M::SecurityGroup, security_group_uuid)
      end
    }

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
          i.ssh_key_pair_id = ssh_key_pair.id
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

    #
    unless params['labels'].blank?
      labels_param_each_pair(params['labels']) do |name, value|
        instance.set_label(name, value)
      end
    end

    if params['volumes'].is_a?(Hash)
      params['volumes'].values.each { |vparam|
        bo = if vparam['backup_object_id'].blank?
               nil
             else
               M::BackupObject[vparam['backup_object_id']] || raise("Unknown backup object: #{vparam['backup_object_id']}")
             end

        if !vparam['size'].blank? && bo
          # create volume from the backup object and grow its size.
          # check size is larger or equal than backup object's size.
          if bo.size > vparam['size'].to_i
            raise "Shrink operation is not supported: size change request from #{bo.size} to #{vparam['size'].to_i}"
          end
          vol = bo.create_volume(instance.account)
          vol.size = vparam['size'].to_i
        elsif !vparam['size'].blank? && bo.nil?
          # create empty volume.
          vol = M::Volume.entry_new(instance.account, vparam['size'].to_i, {})
        elsif vparam['size'].blank? && bo
          # create volume from the backup object.
          vol = bo.create_volume(instance.account)          
        else
          raise "Invalid volume sub parameters: backup_object_id=#{vparam['backup_object_id']}, size=#{vparam['size']}"
        end

        case vparam['volume_type']
        when 'local'
          instance.add_local_volume(vol)
        when 'shared'
          # provisioned by storage scheduler.
          instance.add_shared_volume(vol)
        else
          raise "Invalid volume_type parameter: #{vparam['volume_type']}"
        end
      }
    end
    
    #
    # TODO:
    #  "host_id" and "host_pool_id" will be obsolete.
    #  They are used in lib/dcmgr/scheduler/host_node/specify_node.rb.
    if params[:host_id] || params[:host_pool_id] || params[:host_node_id]
      host_node_id = params[:host_id] || params[:host_pool_id] || params[:host_node_id]
      host_node = M::HostNode[host_node_id]
      raise E::UnknownHostNode, "#{host_node_id}" if host_node.nil?
      raise E::InvalidHostNodeID, "#{host_node_id}" if host_node.status != 'online'

      compat_hype  = (host_node.hypervisor == instance.hypervisor)
      compat_arch = (host_node.arch == instance.image.arch)
      raise E::IncompatibleHostNode, "#{host_node_id} can only handle instances of type #{host_node.arch} #{host_node.hypervisor}" unless compat_arch && compat_hype
      raise E::OutOfHostCapacity, "#{host_node_id}" if instance.cpu_cores > host_node.available_cpu_cores || instance.memory_size > host_node.available_memory_size

      ## Assign the custom host node
      instance.host_node = host_node
      instance.save_changes
    end

    if is_manual_ip_set
      ## Assign the custom vifs
      Dcmgr::Scheduler::Network::SpecifyNetwork.new.schedule(instance)
      instance.network_vif.each { |vif|
        # Calling this scheduler from instance#add_nic method instead
        # as a workaround for that dirty method that needs to be removed
        # Dcmgr::Scheduler::MacAddress::SpecifyMacAddress.new.schedule(vif)

        Dcmgr::Scheduler::IPAddress::SpecifyIP.new.schedule(vif)
      }
    end

    # instance_monitor_attr row is created at after_save hook in Instance model.
    # Note that the keys should use string for sub hash.
    insert_monitoring_items(instance)
    set_monitoring_parameters(instance)

    instance.state = C::Instance::STATE_SCHEDULING
    instance.save_changes
    instance.volumes.each {|v|
      v.state = C::Volume::STATE_SCHEDULING
      v.save_changes
    }

    on_after_commit do
      Dcmgr.messaging.submit("scheduler",
                             'schedule_instance', instance.canonical_uuid)
    end

    respond_with(R::Instance.new(instance).generate)
  end

  delete '/:id' do
    # description 'Shutdown the instance'
    i = find_by_uuid(:Instance, params[:id])

    case i.state
    when C::Instance::STATE_STOPPED
      # just destroy the record.
      i.destroy
    when C::Instance::STATE_TERMINATED, C::Instance::STATE_SCHEDULING
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
    # param :ssh_key_id, string, :optional
    # param :security_groups, array, :optional
    # param :display_name, :string, :optional
    raise E::UndefinedInstanceID if params[:id].nil?

    instance = find_by_uuid(:Instance, params[:id])
    raise E::UnknownInstance if instance.nil?

    if params[:security_groups].is_a?(Array) || params[:security_groups].is_a?(String)
      logger.warn "This code is deprecated and will be removed. Use /network_vifs/:vif_id/add_security_group and /network_vifs/:vif_id/remove_security_group instead."
      # Setting only security groups that are of the same service type as the instance
      # This is to work around a bug where LB security groups would be deleted if the instance
      # is registered to a load balancer
      st = instance.service_type

      security_group_uuids = [params[:security_groups]].flatten.select{|i| !(i.nil? || i == "") }

      groups = security_group_uuids.map {|group_id| find_by_uuid(:SecurityGroup, group_id)}
      # Remove old security groups
      instance.nic.each { |vnic|
        vnic.security_groups_dataset.filter(:service_type => st).each { |group|
          unless security_group_uuids.member?(group.canonical_uuid)
            vnic.remove_security_group(group)
            on_after_commit do
              Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_left",:args=>[vnic.canonical_uuid])
              Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/left_group",:args=>[group.canonical_uuid])

              group.referencees.each { |ref_sg|
                Dcmgr.messaging.event_publish("#{ref_sg.canonical_uuid}/referencer_removed",:args=>[group.canonical_uuid])
              }
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

              group.referencees.each { |ref_sg|
                Dcmgr.messaging.event_publish("#{ref_sg.canonical_uuid}/referencer_added",:args=>[group.canonical_uuid])
              }
            end
          }
        end
      }
    end

    if params[:ssh_key_id]
      ssh_key_pair = M::SshKeyPair[params[:ssh_key_id]]

      if ssh_key_pair.nil?
        raise E::UnknownSshKeyPair, "#{params[:ssh_key_id]}"
      else
        instance.ssh_key_pair_id = ssh_key_pair.id
      end
    end

    if set_monitoring_parameters(instance)
      on_after_commit do
        # instance.monitoring.refreshed is published only when the instance
        # has been running already.
        if instance.state.to_s != 'init'
          Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                        :args=>[{:instance_id=>instance.canonical_uuid}])
        end
      end
    end
    
    instance.display_name = params[:display_name] if params[:display_name]
    instance.save_changes

    respond_with(R::Instance.new(instance).generate)
  end

  # Create image backup from the alive instance.
  quota 'backup_object.count'
  quota 'image.count'
  quota 'instance.backup_operations_per_hour'
  quota('backup_object.size_mb') do
    request_amount do
      instance = find_by_uuid(:Instance, params[:id])
      return (instance.volumes_dataset.attached.sum(:size) / (1024 * 1024)).to_i
    end
  end
  put '/:id/backup' do
    instance = find_by_uuid(:Instance, params[:id])
    raise E::InvalidInstanceState, instance.state unless ['halted'].member?(instance.state)

    # backup storage can be chosen in the order of:
    #   1. query string
    #   2. service type section in dcmgr.conf
    #   3. same location as original backup object.
    bkst_uuid = params[:backup_storage_id] || Dcmgr.conf.service_types[instance.service_type].backup_storage_id
    bkst = if bkst_uuid
             bkst = M::BackupStorage[bkst_uuid] || raise(E::UnknownBackupStorage, bkst_uuid)
           else
             # 3rd case.
             nil
           end

    boot_bko = nil
    bko_list = []
    instance.volumes_dataset.attached.each { |v|
      bo = v.create_backup_object(@account) do |b|
        b.state = C::BackupObject::STATE_PENDING
        if bkst
          b.backup_storage = bkst
        end
      end

      if instance.boot_volume_id == v.canonical_uuid
        boot_bko = bo
      end

      bko_list << bo
    }

    image = instance.image.entry_clone do |i|
      [:display_name, :description, :is_public, :is_cacheable].each { |k|
        if params[k]
          i[k] = params[k]
        end
      }

      i.account_id = @account.canonical_uuid
      i.backup_object_id = boot_bko.canonical_uuid
      i.state = C::Image::STATE_PENDING
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
    raise E::InvalidInstanceState, instance.state unless ['running', 'halting'].member?(instance.state)

    force =
      case params[:force].to_s
      when 'true'
        true
      when 'false'
        false
      else
        Dcmgr.conf.default_force_poweroff_instance
      end
    job_name = force ? 'poweroff' : 'soft_poweroff'
    
    instance.state = :halting
    instance.save

    on_after_commit do
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", job_name,
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

  namespace '/:instance_id/monitoring' do
    def single_insert
      @instance.add_monitor_item(params[:title], params[:enabled]=='true', params[:params])
    end

    before do
      @instance = find_by_uuid(:Instance, params[:instance_id])
    end

    # List monitoring items.
    get do
      respond_with(R::InstanceMonitorItemCollection.new(@instance).generate)
    end

    # Create new monitoring item.
    post do
      res = if params[:title] && params[:enabled]
              single_insert
            else
              raise E::InvalidParameter, "Invalid parameter combination"
            end

      on_after_commit do
        Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                      :args=>[{:instance_id=>@instance.canonical_uuid}])
      end

      respond_with(res)
    end

    # Show single monitoring item.
    get '/:monitor_id' do
      monitor = @instance.monitor_item(params[:monitor_id]) || raise(E::UnknownUUIDResource, params[:monitor_id])
      respond_with(R::InstanceMonitorItem.new(@instance, params[:monitor_id]).generate)
    end

    # Delete single monitoring item.
    delete '/:monitor_id' do
      @instance.delete_monitor_item(params[:monitor_id]) || raise(E::UnknownUUIDResource, params[:monitor_id])

      on_after_commit do
        Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                      :args=>[{:instance_id=>@instance.canonical_uuid, :monitor_id=>params[:monitor_id]}])
      end
      
      respond_with([params[:monitor_id]])
    end

    # Update a monitor parameters.
    put '/:monitor_id' do
      @instance.monitor_item(params[:monitor_id]) || raise(E::UnknownUUIDResource, params[:monitor_id])

      monitor = {}
      unless params[:enabled].blank?
        monitor[:enabled] = (params[:enabled] == 'true')
      end

      monitor[:title] = params[:title] unless params[:title].blank?
      monitor[:params] = params[:params] unless params[:params].blank?
      @instance.update_monitor_item(params[:monitor_id], monitor)

      on_after_commit do
        Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                      :args=>[{:instance_id=>@instance.canonical_uuid, :monitor_id=>params[:monitor_id]}])
      end

      respond_with(R::InstanceMonitorItem.new(@instance, params[:monitor_id]).generate)
    end
  end

  namespace '/:instance_id/volumes' do
    before do
      @instance = find_by_uuid(:Instance, params[:instance_id])
    end

    # list attached volumes to the instance.
    get '' do
      ds = @instance.volumes_dataset
      respond_with(R::VolumeCollection.new(ds))
    end

    # take a backup from the volume.
    quota 'backup_object.count'
    quota 'instance.backup_operations_per_hour'
    quota('backup_object.size_mb') do
      request_amount do
        volume = find_by_uuid(:Volume, params[:id])
        return (volume.size / (1024 * 1024)).to_i
      end
    end
    put '/:id/backup' do
      @volume = find_by_uuid(:Volume, params[:id])
      if @volume.instance != @instance
        raise E::UnknownVolume, @volume.canonical_uuid
      end
      bo = @volume.create_backup_object(@volume.account) do |b|
      end

      on_after_commit do
      end
    end
  end
end
