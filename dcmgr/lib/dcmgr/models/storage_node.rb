# -*- coding: utf-8 -*-

require 'isono'

module Dcmgr::Models
  class StorageNode < BaseNew
    taggable 'sn'

    include Dcmgr::Constants::StorageNode

    plugin :class_table_inheritance, :key=>:storage_type
    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id

    def_dataset_method(:online_nodes) do
      # SELECT * FROM `storage_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'online')))
      r = Isono::Models::NodeState.filter(:state => 'online').select(:node_id)
      # Needs to specify storage_nodes table as this is CTI model.
      filter(:node_id => r, :scheduling_enabled=>true)
    end

    # Returns offline nodes.
    def_dataset_method(:offline_nodes) do
      # SELECT `storage_nodes`.* FROM `storage_nodes` LEFT JOIN `node_states` ON (`storage_nodes`.`node_id` = `node_states`.`node_id`) WHERE ((`node_states`.`state` IS NULL) OR (`node_states`.`state` = 'offline'))
      select_all(:storage_nodes).join_table(:left, :node_states, {:storage_nodes__node_id => :node_states__node_id}).filter({:node_states__state => nil} | {:node_states__state => 'offline'})
    end

    def validate
      super
      # for compatibility: sta.xxx or sta-xxxx
      if self.node_id
        unless self.node_id =~ /^sta[-.]/
          errors.add(:node_id, "is invalid ID: #{self.node_id}")
        end

        if (h = StorageNode.filter(:node_id=>self.node_id).first) && h.id != self.id
          errors.add(:node_id, "#{self.node_id} is already been associated to #{h.canonical_uuid} ")
        end
      end

      #unless self.storage_type
      #  errors.add(:storage_type, "unknown storage type: #{self.storage_type}")
      #end

      unless self.offering_disk_space_mb > 0
        errors.add(:offering_disk_space_mb, "it must have digit more than zero")
      end
    end

    # Show status of the agent.
    def status
      node.nil? ? STATUS_OFFLINE : node.state
    end

    def to_hash
      v = super().merge({:status=>self.status})
      # merge descendant classes attributes.
      self.class.cti_columns.each { |tblname, columns|
        (columns - [self.class.cti_base_model.primary_key]).each { |colname|
          v.merge!({colname.to_sym => self.send(colname)})
        }
      }
      v
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
      convert_byte(volumes_dataset.alives.sum(:size).to_i, byte_unit)
    end

    # Returns available space of the storage node.
    def free_disk_space(byte_unit=B)
      convert_byte((self.offering_disk_space_mb * (1024 ** 2))  - self.disk_usage,
                   byte_unit)
    end

    # Check the free resource capacity across entire local VDC domain.
    def self.check_domain_capacity?(size, num=1)
      alives_size = Volume.dataset.alives.filter.sum(:size).to_i
      offer_size = self.online_nodes.sum(:offering_disk_space_mb).to_i * (1024 ** 2)

      (offer_size - alives_size >= size * num.to_i)
    end

    def associate_volume(volume)
      raise NotImplementedError
    end

    def volumes_dataset
      raise NotImplementedError
    end
  end
end
