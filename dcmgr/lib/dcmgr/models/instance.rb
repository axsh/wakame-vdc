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

      Text :user_data, :null=>false, :default=>''
      Text :runtime_config, :null=>false, :default=>''
      index :state
    end
    with_timestamps
    
    many_to_one :image
    many_to_one :instance_spec
    many_to_one :host_pool
    one_to_many :volume

    subset(:runnings){|f| f.state == :running }

    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    #   kvm:
    # {:vnc_port=>11}
    plugin :serialization
    serialize_attributes :yaml, :runtime_config

    def to_hash
      values.dup.merge({:uuid=>canonical_uuid,
                         :user_data => user_data.to_s,
                         :runtime_config => self.runtime_config, # yaml -> hash
                         :image=>image.to_hash,
                         :host_pool=>host_pool.values
                       }.merge(instance_spec.to_hash))
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

  end
end
