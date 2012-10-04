# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VolumeSnapshot < AccountResource
    taggable 'snap'
    accept_service_type

    STATE_TYPE_REGISTERING = "registering"
    STATE_TYPE_CREATING = "creating"
    STATE_TYPE_AVAILABLE = "available"
    STATE_TYPE_FAILED = "failed"
    STATE_TYPE_DELETING = "deleting"
    STATE_TYPE_DELETED = "deleted"

    many_to_one :storage_node
    plugin ArchiveChangedColumn, :histories

    subset(:alives, {:deleted_at => nil})

    RECENT_TERMED_PERIOD=(60 * 15)
    # lists the volumes are available and deleted within
    # RECENT_TERMED_PERIOD sec.
    def_dataset_method(:alives_and_recent_termed) {
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - RECENT_TERMED_PERIOD))
    }

    class RequestError < RuntimeError; end

    # Hash data for API response.
    def to_api_document
      h = {
        :id => self.canonical_uuid,
        :uuid => self.canonical_uuid,
        :state => self.state,
        :size => self.size,
        :origin_volume_id => self.origin_volume_id,
        :destination_id => self.destination,
        :destination_name => self.display_name,
        :backing_store => self.storage_node.storage_type,
        :created_at => self.created_at,
        :deleted_at => self.deleted_at,
      }
    end

    # create volume inherite from this snapshot for the account.
    # limitation: inherit volume is created on same storage_node.
    def create_volume(account_id)
      storage_node.create_volume(account_id, self.size, self.canonical_uuid)
    end

    def display_name
      repository_config = Dcmgr::StorageService.snapshot_repository_config
      repository = repository_config[self.destination]
      repository['display_name']
    end

    def origin_volume
      Volume[origin_volume_id]
    end

    def snapshot_filename
      "#{self.canonical_uuid}.snap"
    end

    def destination
      self.destination_key.split('@')[0]
    end

    def self.delete_snapshot(account_id, uuid)
      vs = self.dataset.where(:account_id => account_id).where(:uuid => uuid.split('-').last).first
      if vs.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      vs.state = :deleting
      vs.save_changes
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.state = :deleted if self.state != :deleted
      self.deleted_at ||= Time.now
      self.save
    end

    def update_destination_key(account_id, destination_key)
      self.destination_key = destination_key
      self.save_changes
    end

    def self.store_local?(destination)
      destination.nil?
    end

    def update_snapshot_display_name(display_name)
      self.display_name = display_name
      self.save_changes
    end
  end
end
