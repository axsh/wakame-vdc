# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Model class for running virtual instance.
  class Instance < AccountResource
    taggable 'i'

    inheritable_schema do
      Fixnum :host_node_id, :null=>true
      Fixnum :image_id, :null=>false
      Fixnum :instance_spec_id, :null=>false
      String :state, :null=>false, :default=>:init.to_s
      String :status, :null=>false, :default=>:init.to_s
      String :hostname, :null=>false, :size=>32
      # TODO: remove ssh_key_pair_id column
      String :ssh_key_pair_id
      Fixnum :ha_enabled, :null=>false, :default=>0
      Float  :quota_weight, :null=>false, :default=>0.0
      Fixnum :cpu_cores, :null=>false, :unsigned=>true
      Fixnum :memory_size, :null=>false, :unsigned=>true
      
      Text :user_data, :null=>false, :default=>''
      Text :runtime_config, :null=>false, :default=>''
      Text :ssh_key_data, :null=>true
      Text :request_params, :null=>false

      Time :terminated_at
      index :state
      index :terminated_at
      index :host_node_id
    end
    with_timestamps
    
    many_to_one :image
    many_to_one :instance_spec
    alias :spec :instance_spec
    many_to_one :host_node
    one_to_many :volume
    one_to_many :instance_nic
    alias :nic :instance_nic
    many_to_many :netfilter_groups, :join_table=>:instance_netfilter_groups
    # TODO: remove ssh_key_pair_id column
    many_to_one :ssh_key_pair

    plugin ArchiveChangedColumn, :histories
    
    subset(:lives, {:terminated_at => nil})

    RECENT_TERMED_PERIOD=(60 * 15)
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
    # {:vnc_port=>11, :telnet_port=>1111}
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
      
      # check runtime_config column
      if self.host_node
        case self.hypervisor
        when HostNode::HYPERVISOR_KVM
          r1 = self.runtime_config
          self.host_node.instances_dataset.lives.each { |i|
            next true if i.id == self.id
            r2 = i.runtime_config
            unless r1[:vnc_port] != r2[:vnc_port] && r1[:telnet_port] != r2[:telnet_port]
              errors.add(:runtime_config, "#{self.canonical_uuid}.runtime_config conflicted with #{i.canonical_uuid}")
              break
            end
          }
        end
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
      self.remove_all_netfilter_groups
      self.volume.each { |v|
        v.instance_id = nil
        v.state = :available
        v.save
      }
      super
    end

    # override Sequel::Model#_delete not to delete rows but to set
    # delete flags.
    def _delete
      self.terminated_at ||= Time.now
      self.state = :terminated if self.state != :terminated
      self.status = :offline if self.status != :offline
      self.save
    end
    
    # dump column data as hash with details of associated models.
    # this is for internal use.
    def to_hash
      h = super
      h.merge!({:user_data => user_data.to_s, # Sequel::BLOB -> String
                 :runtime_config => self.runtime_config, # yaml -> hash
                 :ssh_key_data => self.ssh_key_data, # yaml -> hash
                 :image=>image.to_hash,
                 :host_node=> (host_node.nil? ? nil : host_node.to_hash),
                 :instance_nics=>instance_nic.map {|n| n.to_hash },
                 :ips => instance_nic.map { |n| n.ip.map {|i| unless i.is_natted? then i.ipv4 else nil end} if n.ip }.flatten.compact,
                 :nat_ips => instance_nic.map { |n| n.ip.map {|i| if i.is_natted? then i.ipv4 else nil end} if n.ip }.flatten.compact,
                 :netfilter_groups => self.netfilter_groups.map {|n| n.name },
              })
      h.merge!({:instance_spec=>instance_spec.to_hash}) unless instance_spec.nil?
      h[:volume]={}
      if self.volume
        self.volume.each { |v|
          h[:volume][v.canonical_uuid] = v.to_hash
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
    #   :netfilter_group => ['rule1', 'rule2']
    #   :created_at
    #   :state
    #   :status
    #   :vif => {'vif-xxxxx'=>{:ipv4=>{:address=>'8.8.8.8', :nat_address=>'9.9.9.9.9'}}}
    # }
    def to_api_document
      h = {
        :id => canonical_uuid,
        :host_node   => self.host_node,
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
        :netfilter_group_id => [],
        :netfilter_group => [],
        :vif => [],
        :hostname => hostname,
        :ha_enabled => ha_enabled,
        :instance_spec_id => instance_spec.canonical_uuid,
      }
      if self.ssh_key_data
        h[:ssh_key_pair] = self.ssh_key_data[:name]
      end

      if instance_nic
        instance_nic.each { |n|
          direct_lease_ds = n.direct_ip_lease_dataset
          next if direct_lease_ds.first.nil?
          outside_lease_ds = n.nat_ip_lease_dataset

          h[:network] << {
            :network_name => n.network.canonical_uuid,
            :ipaddr => direct_lease_ds.all.map {|lease| lease.ipv4 }.compact,
            :dns_name => n.network.domain_name && "#{self.hostname}.#{self.account.uuid}.#{n.network.domain_name}",
            :nat_network_name => n.nat_network && n.nat_network.canonical_uuid,
            :nat_ipaddr => outside_lease_ds.all.map {|lease| lease.ipv4 }.compact,
            :nat_dns_name => n.nat_network && n.nat_network.domain_name && "#{self.hostname}.#{self.account.uuid}.#{n.nat_network.domain_name}"
          }
        }
      end

      if instance_nic
        instance_nic.each { |vif|
          ent = {
            :vif_id=>vif.canonical_uuid,
          }
          direct_lease = vif.direct_ip_lease.first
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
      end
      
      if self.volume
        self.volume.each { |v|
          h[:volume] << {
            :vol_id => v.canonical_uuid,
            :guest_device_name=>v.guest_device_name,
            :state=>v.state,
          }
        }
      end

      if self.netfilter_groups
        self.netfilter_groups.each { |n|
          h[:netfilter_group_id] << n.canonical_uuid
          h[:netfilter_group] << n.name
        }
      end
      h
    end

    # Returns the hypervisor type for the instance.
    def hypervisor
      self.host_node.hypervisor
    end

    # Returns the architecture type of the image
    def arch
      self.image.arch
    end

    def config
      self.instance_spec.config
    end

    def add_nic(network, vendor_id=nil)
      # TODO: get default vendor ID based on the hypervisor.
      vendor_id ||= '00:ff:f1'
      nic = InstanceNic.new(:mac_addr=>vendor_id)
      nic.network = network
      nic.nat_network = network.nat_network
      nic.instance = self
      nic.save
    end

    # Join this instance to the list of netfilter group using group's uuid.
    # @param [String,Array] netfilter_group_uuids 
    def join_netfilter_group(netfilter_group_uuids)
      netfilter_group_uuids = [netfilter_group_uuids] if netfilter_group_uuids.is_a?(String)
      joined_group_uuids = self.netfilter_groups.map { |netfilter_group|
        netfilter_group.canonical_uuid
      }
      target_group_uuids = netfilter_group_uuids.uniq - joined_group_uuids.uniq
      target_group_uuids.uniq!

      target_group_uuids.map { |target_group_uuid|
        if ng = NetfilterGroup[target_group_uuid]
          InstanceNetfilterGroup.create(:instance_id => self.id,
                                        :netfilter_group_id => ng.id)
        end
      }
    end

    def ips
      self.instance_nic.map { |nic| nic.ip }
    end

#    def netfilter_group_instances
#      instances = self.netfilter_groups.map { |g| g.instances }
#
#      instances.flatten!.uniq! if instances.size > 0
#      instances
#    end

    def fqdn_hostname
      sprintf("%s.%s.%s", self.hostname, self.account.uuid, self.nic.first.network.domain_name)
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

    # Join this instance to the list of netfilter group using group name. 
    # @param [String] account_id uuid of current account.
    # @param [String,Array] nfgroup_names 
    def join_nfgroup_by_name(account_id, nfgroup_names)
      nfgroup_names = [nfgroup_names] if nfgroup_names.is_a?(String)

      uuids = nfgroup_names.map { |n|
        ng = NetfilterGroup.for_update.filter(:account_id=>account_id,
                                              :name=>n).first
        ng.nil? ? nil : ng.canonical_uuid
      }
      # clean up nils
      join_netfilter_group(uuids.compact.uniq)
    end

    def self.lock!
      super()
      Image.lock!
      InstanceSpec.lock!
      InstanceNic.lock!
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
      raise ArgumentError unless params.is_a?(::Hash)

      i = self.new &blk
      i.account_id = account.canonical_uuid
      i.image = image
      i.instance_spec = spec
      i.cpu_cores = spec.cpu_cores
      i.memory_size = spec.memory_size
      i.quota_weight = spec.quota_weight
      i.request_params = params

      i
    end
    
  end
end
