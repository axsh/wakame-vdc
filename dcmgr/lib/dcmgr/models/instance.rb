# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Model class for running virtual instance.
  class Instance < AccountResource
    taggable 'i'
    accept_service_type

    many_to_one :image
    many_to_one :host_node
    one_to_many :volume
    one_to_many :network_vif
    alias :instance_nic :network_vif
    alias :nic :network_vif
    many_to_one :ssh_key_pair
    one_to_one :instance_monitor_attr

    plugin ArchiveChangedColumn, :histories
    plugin ChangedColumnEvent, :accounting_log => [:state, :cpu_cores, :memory_size]

    subset(:lives, {:terminated_at => nil})
    subset(:alives, {:terminated_at => nil})
    subset(:runnings, {:state => 'running'})
    subset(:stops, {:state => 'stopped'})

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
      HostnameLease.filter(:account_id=>self.account_id, :hostname=>self.hostname).destroy
      self.instance_nic.each { |o| o.destroy }
      self.volume.each { |v|
        v.instance_id = nil
        v.state = :available
        v.save
      }
      super
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.terminated_at ||= Time.now
      self.state = :terminated if self.state != :terminated
      self.status = :offline if self.status != :offline
      self.save
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
                 :ssh_key_data => self.ssh_key_pair.to_hash,
              })
      h[:volume]={}
      if self.volume
        self.volume.each { |v|
          h[:volume][v.canonical_uuid] = v.to_hash
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
        :instance_spec_id => nil,
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
      Dcmgr::Scheduler.service_type(self).mac_address.schedule(nic)
      nic.save

      if !request_params.has_key?('security_groups') && !vif_template[:security_groups].empty?
        groups = vif_template[:security_groups]
      else
        # TODO: this code will delete. it's remained for compatibility.
        groups = self.request_params["security_groups"]
      end

      if !groups.nil?
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
      raise ArgumentError unless account.is_a?(Account)
      raise ArgumentError unless image.is_a?(Image)
      # Mash is passed in some cases.
      raise ArgumentError unless params.class == ::Hash

      i = self.new &blk
      i.account_id = account.canonical_uuid
      i.image = image
      i.request_params = params.dup

      i
    end

    def on_changed_accounting_log(changed_column)
      AccountingLog.record(self, changed_column)
    end

  end
end
