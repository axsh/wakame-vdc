# -*- coding: utf-8 -*-

require 'multi_json'

module Dcmgr::Models
  # Model class for running virtual instance.
  class Instance < AccountResource
    taggable 'i'
    accept_service_type

    include Dcmgr::Constants::Instance
    
    many_to_one :image
    many_to_one :host_node
    one_to_many :volumes, :before_add=>lambda { |instance, volume|
      hv_class = Dcmgr::Drivers::Hypervisor.driver_class(instance.hypervisor)
      hv_class.policy.on_associate_volume(instance, volume)
      true
    }
    alias :volume :volumes
    one_to_many :local_volumes, :class=>Volume, :read_only=>true do |ds|
      # SELECT volumes.* FROM volumes, l1 LEFT JOIN local_volumes ON self.pk = local_volumes.instance_id
      #   WHERE volumes.id = l1.id
      Volume.left_join(:local_volumes, :instance_id=>self.pk).filter(:local_volumes__id=>:volumes__id)
    end
    one_to_many :network_vif
    alias :instance_nic :network_vif
    alias :nic :network_vif
    many_to_one :ssh_key_pair
    one_to_one :instance_monitor_attr

    plugin ArchiveChangedColumn, :histories
    plugin ChangedColumnEvent, :accounting_log => [:state, :cpu_cores, :memory_size]
    plugin Plugins::ResourceLabel
      
    subset(:lives, {:terminated_at => nil})
    subset(:alives, {:terminated_at => nil})
    subset(:runnings, {:state => STATE_RUNNING})
    subset(:stops, {:state => STATE_STOPPED})

    # lists the instances which alives and died within
    # term_period sec.
    def_dataset_method(:alives_and_termed) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("terminated_at IS NULL OR terminated_at >= ?", (Time.now.utc - term_period))
    }

    def_dataset_method(:without_terminated) do
      filter("state='running' OR state='stopped' OR state='halted'")
    end
    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    #   kvm:
    # {:vnc_port=>11}
    plugin :serialization

    serialize_attributes :yaml, :runtime_config
    # equal to SshKeyPair#to_hash
    serialize_attributes :yaml, :request_params

    module ValidationMethods
      def self.hostname_uniqueness(account_id, hostname)
        HostnameLease.filter(:account_id=>account_id, :hostname=>hostname).empty?
      end
    end

    class HostError < RuntimeError; end

    def validate
      super
      # do not run validation if the row is maked as deleted.
      return true if self.terminated_at

      unless self.hostname =~ /\A[0-9a-z][0-9a-z\-]{0,31}\Z/
        errors.add(:hostname, "Invalid hostname syntax")
      end

      # uniqueness check for hostname
      if changed_columns.include?(:hostname)
        proc_test = lambda {
          unless ValidationMethods.hostname_uniqueness(self.account_id, self.hostname)
            errors.add(:hostname, "Duplicated hostname: #{self.hostname}")
          end
        }

        if new?
          proc_test.call
        else
          orig = self.dup.refresh
          # do nothing if orig.hostname == self.hostname
          if orig.hostname != self.hostname
            proc_test.call
          end
        end
        @update_hostname = true
      end
    end

    def before_validation
      self[:user_data] ||= ''
      self[:hostname] ||= self.uuid
      self[:hostname] = self[:hostname].downcase

      super
    end

    def before_save
      if @update_hostname
        if new?
          HostnameLease.create(:account_id=>self.account_id,
                               :hostname=>self.hostname)
        else
          orig = self.dup.refresh
          # do nothing if orig.hostname == self.hostname
          if orig.hostname != self.hostname

            orig_name = HostnameLease.filter(:account_id=>self.account_id,
                                             :hostname=>orig.hostname).first
            orig_name.hostname = self.hostname
            orig_name.save
          end
        end
        @update_hostname = false
      end

      super
    end

    def after_save
      super

      # force to create one to one association for the monitoring
      # attributes table.
      unless self.instance_monitor_attr
        self.instance_monitor_attr = InstanceMonitorAttr.create
      end
    end

    def before_destroy
      # cancel destroy while backup object is being created.
      unless self.volumes.all? { |v| v.derived_backup_objects_dataset.exclude(:state=>Dcmgr::Const::BackupObject::ALLOW_INSTANCE_DESTROY_STATES).empty? }
        return false
      end
      
      HostnameLease.filter(:account_id=>self.account_id, :hostname=>self.hostname).destroy
      self.instance_nic.each { |o| o.destroy }
      self.volumes_dataset.attached.each { |v|
        v.detach_from_instance
      }
      super
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def _destroy_delete
      self.terminated_at ||= Time.now
      self.state = STATE_TERMINATED if self.state != STATE_TERMINATED
      self.status = STATUS_OFFLINE if self.status != STATUS_OFFLINE
      self.save_changes
    end

    def after_destroy
      super
      if self.service_type == Dcmgr::Constants::LoadBalancer::SERVICE_TYPE
        LoadBalancer.filter(:instance_id=> self.id).destroy
      end
    end

    # dump column data as hash with details of associated models.
    # this is for internal use.
    def to_hash
      h = super
      h.merge!({:image=>image.to_hash,
                 :host_node=> (host_node.nil? ? nil : host_node.to_hash),
                 :instance_nics=>instance_nic.map {|n| n.to_hash },
                 :ips => instance_nic.map { |n| n.ip.map {|i| unless i.is_natted? then i.ipv4 else nil end} if n.ip }.flatten.compact,
                 :nat_ips => instance_nic.map { |n| n.ip.map {|i| if i.is_natted? then i.ipv4 else nil end} if n.ip }.flatten.compact,
                 :vif=>[],
                 :volume=>{},
                 :ssh_key_data => self.ssh_key_pair ? self.ssh_key_pair.to_hash : nil,
              })
      if self.volume
        self.volume.each { |v|
          h[:volume][v.canonical_uuid] = v.to_hash.tap { |h|
            if v.volume_device
              h[:volume_device] = v.volume_device.to_hash
            end
            if v.backup_object
              h[:backup_object] = v.backup_object.to_hash
            end
          }
        }
      end
      if self.instance_nic
        self.instance_nic.each { |vif|
          ent = vif.to_hash.merge({
            :vif_id=>vif.canonical_uuid,
          })
          direct_lease = vif.direct_ip_lease.first
          if direct_lease.nil?
          else
            outside_lease = direct_lease.nat_outside_lease
            ent[:ipv4] = {
              :network => vif.network.nil? ? nil : vif.network.to_hash,
              :address=> direct_lease.ipv4,
              :nat_network => vif.nat_network.nil? ? nil : vif.nat_network.to_hash,
              :nat_address => outside_lease.nil? ? nil : outside_lease.ipv4,
            }
          end
          h[:vif] << ent
        }
      end
      h
    end

    # returns hash data for API response on
    # GET instances/[uuid]
    #
    # @exmaple Example output data.
    # { :id=>
    #   :cpu_cores
    #   :memory_size
    #   :image_id
    #   :network => [{:network_name=>'nw-xxxxxxx', :ipaddr=>'111.111.111.111'}]
    #   :volume => [{'uuid'=>{:guest_device_name=>,}]
    #   :ssh_key_pair => 'xxxxx',
    #   :created_at
    #   :state
    #   :status
    #   :vif => {'vif-xxxxx'=>{:ipv4=>{:address=>'8.8.8.8', :nat_address=>'9.9.9.9.9'}}}
    # }
    def to_api_document
      h = {
        :id => canonical_uuid,
        :host_node   => self.host_node && self.host_node.canonical_uuid,
        :cpu_cores   => cpu_cores,
        :memory_size => memory_size,
        :arch        => image.arch,
        :image_id    => image.canonical_uuid,
        :created_at  => self.created_at,
        :state => self.state,
        :status => self.status,
        :ssh_key_pair => nil,
        :network => [],
        :volume => [],
        :vif => [],
        :hostname => hostname,
        :ha_enabled => ha_enabled,
      }

      if self.ssh_key_pair
        h[:ssh_key_pair] = self.ssh_key_pair.canonical_uuid
      end

      instance_nic.each { |vif|
        direct_lease_ds = vif.direct_ip_lease_dataset
        if direct_lease_ds.first
          outside_lease_ds = vif.nat_ip_lease_dataset

          h[:network] << {
            :network_name => vif.network.canonical_uuid,
            :ipaddr => direct_lease_ds.all.map {|lease| lease.ipv4 }.compact,
            :dns_name => vif.network.domain_name && self.fqdn_hostname,
            :nat_network_name => vif.nat_network && vif.nat_network.canonical_uuid,
            :nat_ipaddr => outside_lease_ds.all.map {|lease| lease.ipv4 }.compact,
            :nat_dns_name => vif.nat_network && vif.nat_network.domain_name && self.nat_fqdn_hostname,
          }
        end

        network = vif.network
        ent = {
          :vif_id => vif.canonical_uuid,
          :network_id => network.nil? ? nil : network.canonical_uuid
        }

        direct_lease = direct_lease_ds.first
        if direct_lease.nil?
        else
          outside_lease = direct_lease.nat_outside_lease
          ent[:ipv4] = {
            :address=> direct_lease.ipv4,
            :nat_address => outside_lease.nil? ? nil : outside_lease.ipv4,
          }
        end

        h[:vif] << ent
      }

      self.volume.each { |v|
        h[:volume] << {
          :vol_id => v.canonical_uuid,
          :guest_device_name=>v.guest_device_name,
          :state=>v.state,
        }
      }

      h
    end

    def add_nic(vif_template)
      # Change all hash keys to symbols (This method expects symbols but the api passes strings so this one-liner makes our life much easier)
      vif_template = Hash[vif_template.map{ |k, v| [k.to_sym, v] }]

      # Choose vendor ID of mac address.
      vendor_id = if vif_template[:vendor_id]
                    vif_template[:vendor_id]
                  else
                    Dcmgr.conf.mac_address_vendor_id
                  end
      nic = NetworkVif.new({ :account_id => self.account_id })
      nic.instance = self
      nic.device_index = vif_template[:index]
      sched = if vif_template[:mac_addr]
        Dcmgr::Scheduler::MacAddress::SpecifyMacAddress.new
      else
        Dcmgr::Scheduler.service_type(self).mac_address
      end

      sched.schedule(nic)
      nic.save

      if !request_params.has_key?('security_groups') && !request_params.has_key?(request_params[:security_groups])
        groups = vif_template["security_groups"] || vif_template[:security_groups]
      else
        # TODO: this code will delete. it's remained for compatibility.
        groups = self.request_params["security_groups"]
      end

      unless groups.nil? || (groups.respond_to?(:empty?) && groups.empty?)
        groups = [groups] unless groups.is_a? Array
        groups.each { |group_id|
          nic.add_security_group(SecurityGroup[group_id])
        }
      end

      nic
    end

    def ips
      self.instance_nic.map { |nic| nic.ip }
    end

    def fqdn_hostname
      self.nic.first.fqdn_hostname
    end

    def nat_fqdn_hostname
      self.nic.first.nat_fqdn_hostname
    end

    # Retrieve all networks belong to this instance
    # @return [Array[Models::Network]]
    def networks
      instance_nic.select { |nic|
        !nic.ip.nil?
      }.map { |nic|
        nic.ip.network
      }.group_by { |net|
        net.canonical_uuid
      }.values.map { |i|
        i.first
      }
    end

    def self.lock!
      super()
      Image.lock!
      NetworkVif.lock!
      Volume.lock!
      VolumeSnapshot.lock!
      IpLease.lock!
    end

    def live?
      self.terminated_at.nil?
    end


    # Factory method for Models::Instance object.
    # This method helps to set association values have to be
    # set mandatry until initial save to the database.
    def self.entry_new(account, image, params, &blk)
      raise ArgumentError, "The account parameter must be an Account. Got '#{account.class}'" unless account.is_a?(Account)
      raise ArgumentError, "The image parameter must be an Image. Got '#{image.class}'" unless image.is_a?(Image)
      # Mash is passed in some cases.
      raise ArgumentError, "The params parameter must be a Hash. Got '#{params.class}'" unless params.class == ::Hash

      # Need to create boot volume first becase boot_volume_id is not
      # null column.
      boot_volume = image.create_volume(account)
      
      instance = self.new
      instance.account_id = account.canonical_uuid
      instance.image = image
      instance.request_params = params.dup
      instance.service_type = image.service_type
      instance.boot_volume_id = boot_volume.canonical_uuid
      if blk
        blk.call(instance)
      end
      # Determine primary key number.
      instance.save

      # set boot volume.
      instance.add_volume(boot_volume)
      boot_volume.state = Dcmgr::Constants::Volume::STATE_SCHEDULING
      boot_volume.save_changes
      
      instance
    end

    def on_changed_accounting_log(changed_column)
      AccountingLog.record(self, changed_column)
    end


    # Find a monitoring item.
    def monitor_item(uuid)
      labels = resource_labels_dataset.grep(:name, "monitoring.items.#{uuid}.%").all
      return nil if labels.empty?

      h={:enabled=>false, :title=>nil, :params=>{}}
      labels.each { |l|
        dummy, dummy, uuid, key = l.name.split('.', 4)
        h[key.to_sym] = case key
                        when 'enabled'
                          l.value == 'true'
                        when 'params'
                          ::MultiJson.load(l.value)
                        else
                          l.value
                        end
      }
      h
    end

    # List all monitoring items.
    def monitor_items
      labels = resource_labels_dataset.grep(:name, "monitoring.items.%").all
      return {} if labels.empty?

      hlist={}
     
      labels.each { |l|
        dummy, dummy, uuid, key = l.name.split('.', 4)
        h = (hlist[uuid] ||= {:enabled=>false, :title=>nil, :params=>{}})
        
        h[key.to_sym] = case key
                        when 'enabled'
                          l.value == 'true'
                        when 'params'
                          ::MultiJson.load(l.value)
                        else
                          l.value
                        end
      }
      hlist
    end
    
    # Add monitor item as resource label.
    def add_monitor_item(title, enabled, params={})
      # generate unique UUID uniqueness from instance's uuid.
      retry_count=3
      begin
        # TODO: generate ID more randomly using rand or hashing library.
        uuid = "imon-" + self.uuid.to_s + (ResourceLabel.dataset.naked.order(Sequel.desc(:id)).get(:id).to_i + retry_count).to_s
        retry_count -= 1
      end while !M::ResourceLabel.dataset.filter(:name=>"monitoring.items.#{uuid}.title").empty? && retry_count > 0
      raise "Failed to generate UUID for new monitor item." if retry_count <= 0
      
      set_label("monitoring.items.#{uuid}.title", title.to_s)
      set_label("monitoring.items.#{uuid}.enabled", enabled.to_s)
      set_label("monitoring.items.#{uuid}.params", ::MultiJson.dump(params))
      {:uuid=>uuid, :title=>title, :enabled=>enabled, :params=>params}
    end

    def update_monitor_item(uuid, data)
      if monitor_item(uuid).nil?
        return nil
      end

      set_label("monitoring.items.#{uuid}.title", data[:title].to_s) if data.has_key?(:title)
      set_label("monitoring.items.#{uuid}.enabled", data[:enabled].to_s) if data.has_key?(:enabled)
      if data.has_key?(:params)
        set_label("monitoring.items.#{uuid}.params", ::MultiJson.dump(data[:params]), :blob_value)
      end
      monitor_item(uuid)
    end
    
    # Delete monitor item from resource label.
    def delete_monitor_item(uuid)
      item = monitor_item(uuid)
      return nil if item.nil?

      clear_labels("monitoring.items.#{uuid}.%")
      item
    end

    def boot_volume
      Volume[self.boot_volume_id]
    end

    def add_local_volume(volume)
      volume.volume_type = LocalVolume.to_s
      volume.save_changes
      self.add_volume(volume)
    end

    def add_shared_volume(volume)
      self.add_volume(volume)
    end

    def volume_guest_device_names(state=Dcmgr::Constants::Volume::STATE_ATTACHED)
      self.volumes_dataset.alives.all.map{|v| v.guest_device_name }
    end

    def ready_poweron?
      # the poweron operation should only be performed to the instance
      # with backup objects don't have working state.
      unless volumes_dataset.alives.all.all? { |v|
          v.derived_backup_objects_dataset.exclude(:state=>Dcmgr::Constants::BackupObject::ALLOW_INSTANCE_POWERON_STATES).empty?
        }
        return false
      end
      true
    end

    def ready_destroy?
      unless volumes_dataset.alives.all.all? { |v|
          v.derived_backup_objects_dataset.exclude(:state=>Dcmgr::Constants::BackupObject::ALLOW_INSTANCE_POWERON_STATES).empty?
        }
        return false
      end
      true
    end
  end
end
