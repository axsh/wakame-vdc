# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Model class which represents Virtual Machine or Isolated Instace
  # running on HostPool.
  #
  # @exmaple Create new instance
  #  hp = HostPool['hp-xxxxx']
  #  inst = hp.create_instance()
  class Instance < AccountResource
    taggable 'i'

    inheritable_schema do
      Fixnum :host_pool_id, :null=>false
      Fixnum :image_id, :null=>false
      Fixnum :instance_spec_id, :null=>false
      String :state, :size=>20, :null=>false, :default=>:init.to_s
      String :status, :size=>20, :null=>false, :default=>:init.to_s
      String :hostname, :null=>false
      String :ssh_key_pair_id
      
      Text :user_data, :null=>false, :default=>''
      Text :runtime_config, :null=>false, :default=>''

      Time   :terminated_at
      index :state
      index :terminated_at
      # can not use same hostname within an account.
      index  [:account_id, :hostname], {:unique=>true}
    end
    with_timestamps
    
    many_to_one :image
    many_to_one :instance_spec
    alias :spec :instance_spec
    many_to_one :host_pool
    one_to_many :volume
    one_to_many :instance_nic
    alias :nic :instance_nic
    one_to_many :instance_netfilter_groups
    many_to_many :netfilter_groups, :join_table=>:instance_netfilter_groups

    subset(:lives, {:terminated_at => nil})
    
    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    #   kvm:
    # {:vnc_port=>11}
    plugin :serialization
    serialize_attributes :yaml, :runtime_config

    def validate
      super

      # TODO: hostname column validation
    end

    def before_validation
      super

      self[:user_data] = '' if self.user_data.nil?
      self[:hostname] = self.uuid if self.hostname.nil?
    end

    # dump column data as hash with details of associated models.
    # this is for internal use.
    def to_hash
      h = super
      h = h.merge({:user_data => user_data.to_s, # Sequel::BLOB -> String
                    :runtime_config => self.runtime_config, # yaml -> hash
                    :image=>image.to_hash,
                    :host_pool=>host_pool.to_hash,
                    :instance_nics=>instance_nic.map {|n| n.to_hash },
                    :instance_spec=>instance_spec.to_hash,
                  })
      h[:volume]={}
      if self.volume
        self.volume.each { |v|
          h[:volume][v.canonical_uuid] = v.to_hash_document
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
    #   :network => {'global1'=>{:ipaddr=>'111.111.111.111'}}
    #   :volume => {'uuid'=>{:guest_device_name=>,}}
    #   :created_at
    #   :state
    #   :status
    # }
    def to_api_document
      h = {
        :id => canonical_uuid,
        :cpu_cores   => instance_spec.cpu_cores,
        :memory_size => instance_spec.memory_size,
        :image_id    => image.canonical_uuid,
        :created_at  => self.created_at,
        :state => self.state,
        :status => self.status,
      }

      h[:network] = []
      if instance_nic
        instance_nic.each { |n|
          if n.ip
            h[:network] << {
              :network_name => n.ip.network.name,
              :ipaddr => n.ip.ipv4
            }
          end
        }
      end
      
      h[:volume] = []
      if self.volume
        self.volume.each { |v|
          h[:volume] << {
            :vol_id => v.canonical_uuid,
            :guest_device_name=>v.guest_device_name,
            :state=>v.state,
          }
        }
      end
      h
    end

    # Returns the hypervisor type for the instance.
    def hypervisor
      self.host_pool.hypervisor
    end

    # Returns the architecture type of the image
    def arch
      self.image.arch
    end

    def cpu_cores
      self.instance_spec.cpu_cores
    end

    def memory_size
      self.instance_spec.memory_size
    end

    def config
      self.instance_spec.config
    end

    def add_nic(vifname=nil, vendor_id=nil)
      vifname ||= "vif-#{self[:uuid]}"
      # TODO: get default vendor ID based on the hypervisor.
      vendor_id ||= '00:ff:f1'
      nic = InstanceNic.new({:vif=>vifname,
                              :mac_addr=>vendor_id
                            })
      nic.instance = self
      nic.save
    end

    def join_netfilter_group(netfilter_group_uuids)
      joined_group_uuids = self.netfilter_groups.map { |netfilter_group|
        netfilter_group.canonical_uuid
      }
      target_group_uuids = netfilter_group_uuids.uniq - joined_group_uuids.uniq
      target_group_uuids.uniq!

      target_group_uuids.map { |target_group_uuid|
        if ng = Models::NetfilterGroup[target_group_uuid]
          InstanceNetfilterGroup.create(:instance_id => self.id,
                                        :netfilter_group_id => ng.id)
        end
      }
    end

    def ips
      self.instance_nic.map { |nic| nic.ip }
    end

    def netfilter_group_instances
      instances = self.netfilter_groups.map { |g| g.instances }

      instances.flatten!.uniq! if instances.size > 0
      instances
    end

    def fqdn_hostname
      sprintf("%s.%s.%s", self.hostname, self.account.uuid, self.host_pool.network.domain_name)
    end

    # Retrieve all networks belong to this instance
    # @return [Array[Models::Network]]
    def networks
      instance_nic.select { |nic|
        !nic.ip.nil?
      }.map { |nic|
        nic.ip.network
      }.group_by { |net|
        net.name
      }.values.map { |i|
        i.first
      }
    end

  end
end
