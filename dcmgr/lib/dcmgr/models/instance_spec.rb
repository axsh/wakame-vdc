# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceSpec < AccountResource
    taggable 'is'

    inheritable_schema do
      String :hypervisor, :null=>false
      String :arch, :null=>false
      
      Fixnum :cpu_cores, :null=>false, :unsigned=>true
      Fixnum :memory_size, :null=>false, :unsigned=>true
      Text :config, :null=>false, :default=>''
    end
    with_timestamps
    
  end
end
