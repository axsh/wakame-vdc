# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceSpec < AccountResource
    taggable 'is'

    inheritable_schema do
      String :hypervisor, :null=>false
      String :arch, :null=>false
      
      Fixnum :cpu_cores, :null=>false, :unsigned=>true
      Fixnum :memory_size, :null=>false, :unsigned=>true
      Float  :quota_weight, :null=>false, :default=>1.0
      Text :config, :null=>false, :default=>''
    end
    with_timestamps

    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    #   hypervisor=kvm:
    # {:block_driver=>'virtio', :nic_driver=>'virtio'}
    plugin :serialization
    serialize_attributes :yaml, :config

    def before_validate
      default_config =
        case self.hypervisor
        when HostPool::HYPERVISOR_KVM
          {:block_driver=>'virtio', :nic_driver=>'virtio'}
        end

      self.config = default_config.merge(self.config || {})
      super
    end

    def to_hash
      super.merge({:config=>self.config, # yaml -> Hash
                  })
    end

    def to_api_document
      doc = super()
      doc.delete(:config)
      doc
    end
  end
end
