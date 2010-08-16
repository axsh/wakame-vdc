# -*- coding: utf-8 -*-

module Dcmgr::Models
  class HostPool < AccountResource
    taggable 'hp'
    with_timestamps

    HYPERVISOR_XEN_34=:'xen-3.4'
    HYPERVISOR_XEN_40=:'xen-4.0'

    ARCH_X86=:x86
    ARCH_X86_64=:x86_64
    
    inheritable_schema do
      Fixnum :state, :null=>false, :default=>0
      Fixnum :status, :null=>false, :default=>0

      String :arch, :size=>10, :null=>false # :x86, :x86_64
      String :hypervisor, :size=>10, :null=>false
      Fixnum :cpu_cores, :null=>false, :unsigned=>true
      Fixnum :memory_size, :null=>false, :unsigned=>true

      Fixnum :offering_cpu_cores,   :null=>false, :unsigned=>true
      Fixnum :offering_memory_size, :null=>false, :unsigned=>true
      Fixnum :allow_memory_overcommit, :null=>false, :default=>1
    end
    
    one_to_many :instances

    def after_initialize
      super

      self[:offering_cpu_cores] ||= self.cpu_cores
      self[:offering_memory_size] ||= self.memory_size
    end

    def validate
      unless [:x86, :x86_64].member?(self.arch.to_sym)
        errors.add(:arch, "unknown architecture type: #{self.arch}")
      end

      unless self.offering_cpu_cores > 0
        errors.add(:offering_cpu_cores, "it must have digit more than zero")
      end
      unless self.offering_memory_size > 0
        errors.add(:offering_memory_size, "it must have digit more than zero")
      end
    end

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end

    # Check if the resources exist depending on the HostPool.
    # @return [boolean] 
    def depend_resources?
      !self.instances_dataset.runnings.empty?
    end
    
    # Factory method for Instance model to run on this HostPool.
    def create_instance(image_uuid, &blk)
      i = Instance.new &blk
      i.image = Image[image_uuid]
      i.host_pool = self
      i.save
    end
    
  end

end
