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
    end
    with_timestamps
    
    many_to_one :image
    many_to_one :instance_spec
    many_to_one :host_pool

    subset(:runnings){|f| f.state == :running }

    def to_hash
      values.dup.merge({:uuid=>canonical_uuid,
                         :user_data => user_data.to_s,
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
