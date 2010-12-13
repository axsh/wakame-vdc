# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VolumeSnapshot < AccountResource
    taggable 'snap'

    STATE_TYPE_REGISTERING = "registering"
    STATE_TYPE_CREATING = "creating"
    STATE_TYPE_AVAILABLE = "available"
    STATE_TYPE_FAILED = "failed"
    STATE_TYPE_DELETING = "deleting"
    STATE_TYPE_DELETED = "deleted"

    inheritable_schema do
      Fixnum :storage_pool_id, :null=>false
      String :origin_volume_id, :null=>false
      Fixnum :size, :null=>false
      Fixnum :status, :null=>false, :default=>0
      String :state, :null=>false, :default=>STATE_TYPE_REGISTERING
      index :storage_pool_id
    end
    with_timestamps

    many_to_one :storage_pool
    plugin ArchiveChangedColumn, :histories

    class RequestError < RuntimeError; end

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end

    # Hash data for API response.
    def to_api_document
      h = {
        :id => self.canonical_uuid,
        :state => self.state,
        :size => self.size,
        :origin_volume_id => self.origin_volume_id,
        :created_at => self.created_at,
      }
    end

    # create volume inherite from this snapshot for the account.
    # limitation: inherit volume is created on same storage_pool.
    def create_volume(account_id)
      storage_pool.create_volume(account_id, self.size, self.canonical_uuid)
    end

    def origin_volume
      Volume[origin_volume_id]
    end

    def self.delete_snapshot(account_id, uuid)
      vs = self.dataset.where(:account_id => account_id).where(:uuid => uuid.split('-').last).first
      if vs.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      vs.state = :deleting
      vs.save_changes
    end
  end
end
