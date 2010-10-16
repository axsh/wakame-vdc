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
      String :state, :size=>20, :null=>false, :default=>:init.to_s
      String :status, :size=>20, :null=>false, :default=>:init.to_s
      
      Fixnum :cpu_cores, :null=>false, :unsigned=>true
      Fixnum :memory_size, :null=>false, :unsigned=>true
      String :user_data
    end
    with_timestamps
    
    many_to_one :image
    many_to_one :host_pool

    subset(:runnings){|f| f.state == STATUS_TYPE_RUNNING }

    # Returns the hypervisor type for the instance.
    def hypervisor
      self.host_pool.hypervisor
    end

    # Returns the architecture type of the image
    def arch
      self.image.arch
    end

  end
end
