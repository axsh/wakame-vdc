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

    STATUS_TYPE_NONE = -1
    STATUS_TYPE_OFFLINE = 0
    STATUS_TYPE_RUNNING = 1
    STATUS_TYPE_ONLINE = 2
    STATUS_TYPE_TERMINATING = 3
    
    STATUS_MSGS = {
      STATUS_TYPE_OFFLINE => :offline,
      STATUS_TYPE_RUNNING => :running,
      STATUS_TYPE_ONLINE => :online,
      STATUS_TYPE_TERMINATING => :terminating,
    }
    
    inheritable_schema do
      Fixnum :host_pool_id, :null=>false
      Fixnum :image_id, :null=>false
      Fixnum :state, :null=>false, :default=>STATUS_TYPE_NONE
      Fixnum :status, :null=>false, :default=>STATUS_TYPE_NONE
      
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
