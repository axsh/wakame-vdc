# -*- coding: utf-8 -*-

module Dcmgr::Models
  class BackupStorage < BaseNew
    taggable 'bkst'

    STORAGE_TYPES=[:local, :webdav, :s3, :iijgio, :ifs].freeze
    one_to_many :backup_objects

    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id

    def_dataset_method(:online_nodes) do
      # SELECT * FROM `storage_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'online')))
      r = Isono::Models::NodeState.filter(:state => 'online').select(:node_id)
      filter(:node_id => r)
    end
    
    def validate
      unless STORAGE_TYPES.member?(self.storage_type.to_sym)
        errors.add(:storage_type, "Unknown storage type: #{self.storage_type}")
      end
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.save_changes
    end
  end
end
