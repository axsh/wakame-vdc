# -*- coding: utf-8 -*-

require 'isono'

module Dcmgr::Models
  class HostNode < BaseNew
    taggable 'hn'

    include Dcmgr::Constants::HostNode

    one_to_many :instances
    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id

    one_to_many :host_node_vnet
    alias :vnet :host_node_vnet

    one_to_many :local_volumes

    def_dataset_method(:online_nodes) do
      # SELECT * FROM `host_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'online')))
      r = Isono::Models::NodeState.filter(:state => 'online').select(:node_id)
      filter(:node_id => r, :enabled=>true)
    end

    def_dataset_method(:offline_nodes) do
      # SELECT `host_nodes`.* FROM `host_nodes` LEFT JOIN `node_states` ON (`host_nodes`.`node_id` = `node_states`.`node_id`) WHERE ((`node_states`.`state` IS NULL) OR (`node_states`.`state` = 'offline'))
      select_all(:host_nodes).join_table(:left, :node_states, {:host_nodes__node_id => :node_states__node_id}).filter({:node_states__state => nil} | {:node_states__state => 'offline'} | {:host_nodes__enabled=>false})
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
      node.nil? ? STATUS_OFFLINE : node.state
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

    def alive_vnics_dataset
      NetworkVif.filter(:instance => Instance.alives.filter(:host_node => self))
    end

    # Returns all vnics on this host
    def alive_vnics
      alive_vnics_dataset.all
    end

    def security_groups_dataset
      SecurityGroup.filter(:network_vif => alive_vnics_dataset)
    end

    # Returns all security groups that have vnics on this host
    def security_groups
      security_groups_dataset.all
    end

    def to_api_document
      h = super()
      h.merge!(:status=>self.status)
      h.delete(:node_id)
      h
    end

    def compatible_arch?(a)
      comp_archs = case self.arch
      when ARCH_X86_64
        [ARCH_X86,ARCH_X86_64]
      when ARCH_X86
        [ARCH_X86]
      end

      comp_archs.member?(a)
    end

    # Returns reserved CPU cores used by running/scheduled instances.
    def cpu_core_usage
      instances_usage(:cpu_cores)
    end

    def cpu_core_usage_percent()
      (cpu_core_usage.to_f / offering_cpu_cores.to_f) * 100.0
    end

    # Returns reserved memory size used by running/scheduled instances.
    def memory_size_usage
      instances_usage(:memory_size)
    end

    def memory_size_usage_percent()
      (memory_size_usage.to_f / offering_memory_size.to_f) * 100.0
    end

    # Calc all local volume size on this host node.
    def disk_space_usage
      instances_dataset.alives.map { |i|
        i.local_volumes_dataset.sum(:size).to_i
      }.inject{|r, i| r + i }.to_i
    end

    def disk_space_usage_percent()
      (disk_space_usage.to_f / (offering_disk_space_mb * (1024 ** 2)).to_f) * 100.0
    end

    # Returns a usage percentage to show admins in quick overviews
    def usage_percent
      cpu_percent = (cpu_core_usage.to_f / offering_cpu_cores.to_f) * 100
      mem_percent = (memory_size_usage.to_f / offering_memory_size.to_f) * 100

      ((cpu_percent + mem_percent) / 2).to_i
    end

    # Returns available CPU cores.
    def available_cpu_cores
      self.offering_cpu_cores - self.cpu_core_usage
    end

    # Returns available memory size.
    def available_memory_size
      self.offering_memory_size - self.memory_size_usage
    end

    # Returns available memory size.
    def available_disk_space
      (self.offering_disk_space_mb * 1024 * 1024) - self.disk_space_usage
    end

    # Check the free resource capacity across entire local VDC domain.
    def self.check_domain_capacity?(cpu_cores, memory_size, num=1)
      ds = Instance.dataset.lives.filter(:host_node => HostNode.online_nodes)
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
