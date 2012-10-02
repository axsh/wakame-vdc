# -*- coding: utf-8 -*-

require 'isono/models/node_state'

module Dcmgr::Models
  class HostNode < BaseNew
    taggable 'hn'

    HYPERVISOR_XEN_34='xen-3.4'
    HYPERVISOR_XEN_40='xen-4.0'
    HYPERVISOR_KVM='kvm'
    HYPERVISOR_LXC='lxc'
    HYPERVISOR_ESXI='esxi'
    HYPERVISOR_OPENVZ='openvz'

    ARCH_X86=:x86.to_s
    ARCH_X86_64=:x86_64.to_s

    SUPPORTED_ARCH=[ARCH_X86, ARCH_X86_64]
    SUPPORTED_HYPERVISOR=[HYPERVISOR_KVM, HYPERVISOR_LXC, HYPERVISOR_ESXI, HYPERVISOR_OPENVZ]

    one_to_many :instances
    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id

    one_to_many :host_node_vnet
    alias :vnet :host_node_vnet

    def_dataset_method(:online_nodes) do
      # SELECT * FROM `host_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'online')))
      r = Isono::Models::NodeState.filter(:state => 'online').select(:node_id)
      filter(:node_id => r)
    end

    def_dataset_method(:offline_nodes) do
      # SELECT * FROM `host_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'offline')))
      r = Isono::Models::NodeState.filter(:state => 'offline').select(:node_id)
      filter(:node_id => r)
    end
    
    def validate
      super
      # for compatibility: hva.xxx or hva-xxxx
      if self.node_id
        unless self.node_id =~ /^hva[-.]/
          errors.add(:node_id, "is invalid ID: #{self.node_id}")
        end
        
        if (h = self.class.filter(:node_id=>self.node_id).first) && h.id != self.id
          errors.add(:node_id, "#{self.node_id} is already been associated to #{h.canonical_uuid} ")
        end
      end
      
      unless SUPPORTED_ARCH.member?(self.arch)
        errors.add(:arch, "unknown architecture type: #{self.arch}")
      end

      unless self.offering_cpu_cores > 0
        errors.add(:offering_cpu_cores, "it must have digit more than zero")
      end
      unless self.offering_memory_size > 0
        errors.add(:offering_memory_size, "it must have digit more than zero")
      end
    end

    def to_hash
      super.merge(:status=>self.status)
    end

    # Check if the resources exist depending on the HostNode.
    # @return [boolean] 
    def depend_resources?
      !self.instances_dataset.runnings.empty?
    end
    
    def status
      node.nil? ? :offline : node.state
    end

    # Returns true/false if the host node has enough capacity to run
    # the given instance.
    # @param [Instance] instance
    def check_capacity(instance)
      raise ArgumentError unless instance.is_a?(Instance)

      using_cpu_cores, using_memory_size = self.instances_dataset.lives.select { [sum(:cpu_cores), sum(:memory_size)] }.naked.first.values.map {|i| i || 0}

      (self.offering_cpu_cores >= using_cpu_cores + instance.cpu_cores) &&
        (self.offering_memory_size >= using_memory_size + instance.memory_size)
    end
    
    def to_api_document
      h = super()
      h.merge!(:status=>self.status)
      h.delete(:node_id)
      h
    end

    # Returns reserved CPU cores used by running/scheduled instances.
    def cpu_core_usage
      instances_usage(:cpu_cores)
    end

    # Returns reserved memory size used by running/scheduled instances.
    def memory_size_usage
      instances_usage(:memory_size)
    end

    # Returns available CPU cores.
    def available_cpu_cores
      self.offering_cpu_cores - self.cpu_core_usage
    end

    # Returns available memory size.
    def available_memory_size
      self.offering_memory_size - self.memory_size_usage
    end

    # Check the free resource capacity across entire local VDC domain.
    def self.check_domain_capacity?(cpu_cores, memory_size, num=1)
      ds = Instance.dataset.lives
      alives_cpu_cores, alives_mem_size = ds.select{[sum(:cpu_cores), sum(:memory_size)]}.naked.first.values.map { |i| i || 0 }
      stopped_cpu_cores, stopped_mem_size = ds.filter(:state=>'stopped').select{ [sum(:cpu_cores), sum(:memory_size)] }.naked.first.values.map { |i| i || 0 }
      # instance releases the resources during stopped state normally. however admins may
      # want to manage the reserved resource ratio for stopped
      # instances. "stopped_instance_usage_factor" conf parameter allows its control.
      # 
      # * stopped_instance_usage_factor == 1.0 means that 100% of
      # resources are reserved for stopped instances. all of them will
      # success to start up but utilization of host notes will be dropped.
      # * stopped_instance_usage_factor == 0.5 means that 50% of
      # resources for stopped instances are reserved and rest of 50%
      # may fail to start again.
      usage_factor = (Dcmgr.conf.stopped_instance_usage_factor || 1.0).to_f

      offer_cpu, offer_mem = self.online_nodes.select { [sum(:offering_cpu_cores), sum(:offering_memory_size)] }.naked.first.values.map {|i| i || 0 }
      avail_mem_size = offer_mem - ((alives_mem_size - stopped_mem_size) + (stopped_mem_size * usage_factor).floor)
      avail_cpu_cores = offer_cpu - ((alives_cpu_cores - stopped_cpu_cores) + (stopped_cpu_cores * usage_factor).floor)
      
      (avail_mem_size >= memory_size * num.to_i) && (avail_cpu_cores >= cpu_cores * num.to_i)
    end

    def add_vnet(network)
      m = MacLease.lease(Dcmgr.conf.mac_address_vendor_id)
      hn_vnet = HostNodeVnet.new
      hn_vnet.host_node = self
      hn_vnet.network = network
      hn_vnet.broadcast_addr = m.pretty_mac_addr('')
      hn_vnet.save
      hn_vnet
    end

    # Returns the host node groups that this node is part of
    def groups_dataset
      Tag.filter(:mapped_uuids => TagMapping.filter(:uuid => self.canonical_uuid))
    end

    def groups
      groups_dataset.all
    end

    protected
    def instances_usage(colname)
      instances_dataset.lives.sum(colname).to_i
    end
  end
end
