# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Model class for running virtual instance.
  class Instance < AccountResource
    taggable 'i'

    many_to_one :image
    many_to_one :instance_spec
    alias :spec :instance_spec
    many_to_one :host_node
    one_to_many :volume
    one_to_many :network_vif
    alias :instance_nic :network_vif
    alias :nic :network_vif
    many_to_many :security_groups, :join_table=>:instance_security_groups
    # TODO: remove ssh_key_pair_id column
    many_to_one :ssh_key_pair

    plugin ArchiveChangedColumn, :histories
    
    subset(:lives, {:terminated_at => nil})
    subset(:runnings, {:state => 'running'})
    subset(:stops, {:state => 'stopped'})

    #RECENT_TERMED_PERIOD=(60 * 15)
    RECENT_TERMED_PERIOD = Dcmgr.conf.recent_terminated_instance_period
    # lists the instances which alives and died within
    # RECENT_TERMED_PERIOD sec.
    # it was difficult for me to write exprs in virtual row syntax as
    # per subset(). ;-(
    def_dataset_method(:alives_and_recent_termed) {
      filter("terminated_at IS NULL OR terminated_at >= ?", (Time.now.utc - RECENT_TERMED_PERIOD))
    }
    
    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    #   kvm:
    # {:vnc_port=>11}
    plugin :serialization
    serialize_attributes :yaml, :runtime_config
    # equal to SshKeyPair#to_hash
    serialize_attributes :yaml, :ssh_key_data
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

      # sum() returns nil if there is no instance rows.
      lives_weight = self.class.filter(:account_id=>self.account_id).lives.sum(:quota_weight) || 0.0
      unless lives_weight <= self.account.quota.instance_total_weight
        raise HostError, "Out of quota limit: #{self.account_id}'s current weight capacity: #{lives_weight} (<= #{self.account.quota.instance_total_weight})"
      end

      super
    end

    def before_destroy
      HostnameLease.filter(:account_id=>self.account_id, :hostname=>self.hostname).destroy
      self.instance_nic.each { |o| o.destroy }
      self.remove_all_security_groups
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
                 :security_groups => self.security_groups.map {|n| n.canonical_uuid },
                 :vif=>[],
              })
      h.merge!({:instance_spec=>instance_spec.to_hash}) unless instance_spec.nil?
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
    #   :security_groups => ['rule1', 'rule2']
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
        :arch        => spec.arch,
        :image_id    => image.canonical_uuid,
        :created_at  => self.created_at,
        :state => self.state,
        :status => self.status,
        :ssh_key_pair => nil,
        :network => [],
        :volume => [],
        :security_groups => self.security_groups.map {|n| n.canonical_uuid },
        :vif => [],
        :hostname => hostname,
        :ha_enabled => ha_enabled,
        :instance_spec_id => instance_spec.canonical_uuid,
      }
      if self.ssh_key_data
        h[:ssh_key_pair] = self.ssh_key_data[:uuid]
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

    # Returns the hypervisor type for the instance.
    def hypervisor
      self.instance_spec.hypervisor
    end

    # Returns the architecture type of the image
    def arch
      self.image.arch
    end

    def config
      self.instance_spec.config
    end

    def add_nic(vif_template)
      # Choose vendor ID of mac address.
      vendor_id = if vif_template[:vendor_id]
                    vif_template[:vendor_id]
                  elsif Dcmgr.conf.mac_address_vendor_id
                    Dcmgr.conf.mac_address_vendor_id
                  else
                    MacLease.default_vendor_id(self.instance_spec.hypervisor)
                  end
      m = MacLease.lease(vendor_id)
      nic = NetworkVif.new(:mac_addr=>m.mac_addr)
      nic.instance = self
      nic.device_index = vif_template[:index]
      nic.save
    end

    # Join this instance to the list of security group using group's uuid.
    # @param [String,Array] security_group_uuids 
    def join_security_group(security_group_uuids)
      security_group_uuids = [security_group_uuids] if security_group_uuids.is_a?(String)
      joined_group_uuids = self.security_groups.map { |security_group|
        security_group.canonical_uuid
      }
      target_group_uuids = security_group_uuids.uniq - joined_group_uuids.uniq
      target_group_uuids.uniq!

      target_group_uuids.map { |target_group_uuid|
        if sg = SecurityGroup[target_group_uuid]
          InstanceSecurityGroup.create(:instance_id => self.id,
                                       :security_group_id => sg.id)
        end
      }
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
      InstanceSpec.lock!
      NetworkVif.lock!
      Volume.lock!
      VolumeSnapshot.lock!
      IpLease.lock!
    end

    def live?
      self.terminated_at.nil?
    end

    def set_ssh_key_pair(ssh_key_pair)
      raise ArgumentError unless ssh_key_pair.is_a?(SshKeyPair)
      self.ssh_key_data = ssh_key_pair.to_hash
      # Do not copy private key.
      self.ssh_key_data.delete(:private_key)
      # TODO: remove ssh_key_pair_id column
      self.ssh_key_pair_id = ssh_key_pair.canonical_uuid
    end


    # Factory method for Models::Instance object.
    # This method helps to set association values have to be
    # set mandatry until initial save to the database.
    def self.entry_new(account, image, spec, params, &blk)
      raise ArgumentError unless account.is_a?(Account)
      raise ArgumentError unless image.is_a?(Image)
      raise ArgumentError unless spec.is_a?(InstanceSpec)
      # Mash is passed in some cases.
      raise ArgumentError unless params.class == ::Hash

      i = self.new &blk
      i.account_id = account.canonical_uuid
      i.image = image
      i.instance_spec = spec
      i.cpu_cores = spec.cpu_cores
      i.memory_size = spec.memory_size
      i.quota_weight = spec.quota_weight
      i.request_params = params.dup

      i
    end

  end
end
