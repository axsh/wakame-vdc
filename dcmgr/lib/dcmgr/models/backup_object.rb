# -*- coding: utf-8 -*-

module Dcmgr::Models
  class BackupObject < AccountResource
    taggable 'bo'
    accept_service_type

    include Dcmgr::Constants::BackupObject

    many_to_one :backup_storage
    plugin ArchiveChangedColumn, :histories
    # TODO put logs to accounting log.
    plugin Plugins::ResourceLabel

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }

    def after_initialize
      super
      self[:object_key] ||= self.canonical_uuid
    end

    def validate
      self.container_format ||= :raw
      unless CONTAINER_FORMAT.keys.member?(self.container_format.to_sym)
        errors.add(:container_format, "Unsupported container format: #{self.container_format}")
      end

      errors.add(:size, "Invalid size: #{self.size}") if self.size < 0
      if !self.allocation_size.nil?
        # allocation_size is NULL column. so check only if not null.
        errors.add(:allocation_size, "Invalid size: #{self.allocation_size}") if self.allocation_size.to_i < 0
      end

      unless self.progress.to_f.between?(0.0, 100.0)
        errors.add(:progress, "Must be set between 0.0-100.0.")
      end
    end

    def self.entry_new(bkst, account, size, &blk)
      bo = self.new
      bo.backup_storage = (bkst.is_a?(BackupStorage) ? bkst : BackupStorage[bkst.to_s])
      bo.account_id = (account.is_a?(Account) ? account.canonical_uuid : account.to_s)
      bo.size = size.to_i
      bo.state = STATE_CREATING
      blk.call(bo)
      bo.save
    end

    def entry_clone(&blk)
      self.class.entry_new(self.backup_storage, self.account_id, self.size) do |i|
        i.display_name = self.display_name
        i.description = "#{self.description} (copy of #{self.canonical_uuid})"
        i.container_format = self.container_format
        blk.call(i) if blk
      end
    end

    def uri
      self.backup_storage.base_uri + self.object_key
    end

    def to_hash
      super.merge(:backup_storage=> self.backup_storage.to_hash)
    end

    def create_volume(account=nil)
      Volume.entry_new(account || self.account, self.size, {}) do |v|
        v.backup_object_id = self.canonical_uuid
      end
    end

    private

    def before_save
      if self.state == STATE_AVAILABLE
        self.progress = 100.0
      end

      super
    end

    def _destroy_delete
      self.state = STATE_DELETED if self.state != STATE_DELETED
      self.deleted_at ||= Time.now
      self.save_changes
    end

  end
end
