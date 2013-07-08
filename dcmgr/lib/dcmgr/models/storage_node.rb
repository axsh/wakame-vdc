# -*- coding: utf-8 -*-

require 'isono/models/node_state'

module Dcmgr::Models
  class StorageNode < BaseNew
    taggable 'sn'

    include Dcmgr::Constants::StorageNode

    one_to_many :volumes
    one_to_many :volume_snapshots

    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id

    def_dataset_method(:online_nodes) do
      # SELECT * FROM `storage_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'online')))
      r = Isono::Models::NodeState.filter(:state => 'online').select(:node_id)
      filter(:node_id => r)
    end

    def validate
      super
      # for compatibility: sta.xxx or sta-xxxx
      if self.node_id
        unless self.node_id =~ /^sta[-.]/
          errors.add(:node_id, "is invalid ID: #{self.node_id}")
        end

        if (h = self.class.filter(:node_id=>self.node_id).first) && h.id != self.id
          errors.add(:node_id, "#{self.node_id} is already been associated to #{h.canonical_uuid} ")
        end
      end

      unless SUPPORTED_BACKINGSTORE.member?(self.storage_type)
        errors.add(:storage_type, "unknown storage type: #{self.storage_type}")
      end

      unless self.offering_disk_space_mb > 0
        errors.add(:offering_disk_space_mb, "it must have digit more than zero")
      end
    end

    # Show status of the agent.
    def status
      node.nil? ? STATUS_OFFLINE : node.state
    end

    def to_hash
      super.merge({:status=>self.status})
    end

    def to_api_document
      h = super()
      h.merge!(:status=>self.status)
      h.delete(:node_id)
      h
    end

    include Dcmgr::Helpers::ByteUnit

    # Returns total disk usage of associated volumes.
    def disk_usage(byte_unit=B)
      convert_byte(volumes_dataset.lives.sum(:size).to_i, byte_unit)
    end

    # Returns available space of the storage node.
    def free_disk_space(byte_unit=B)
      convert_byte((self.offering_disk_space_mb * (1024 ** 2))  - self.disk_usage,
                   byte_unit)
    end

    # Check the free resource capacity across entire local VDC domain.
    def self.check_domain_capacity?(size, num=1)
      alives_size = Volume.dataset.lives.filter.sum(:size).to_i
      offer_size = self.online_nodes.sum(:offering_disk_space_mb).to_i * (1024 ** 2)

      (offer_size - alives_size >= size * num.to_i)
    end

  end
end
