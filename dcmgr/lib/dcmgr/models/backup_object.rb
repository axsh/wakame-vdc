# -*- coding: utf-8 -*-

module Dcmgr::Models
  class BackupObject < AccountResource
    taggable 'bo'
    accept_service_type

    many_to_one :backup_storage
    plugin ArchiveChangedColumn, :histories
    # TODO put logs to accounting log.

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }
    
    class RequestError < RuntimeError; end

    def after_initialize
      super
      self.object_key ||= self.canonical_uuid
    end
    
    def self.entry_new(bkst, account, size, &blk)
      bo = self.new
      bo.backup_storage = (bkst.is_a?(BackupStorage) ? bkst : BackupStorage[bkst.to_s])
      bo.account_id = (account.is_a?(Account) ? account.canonical_uuid : account.to_s)
      bo.size = size.to_i
      bo.state = :creating
      blk.call(bo)
      bo.save
    end

    def entry_delete
      if self.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      self.state = :deleting
      self.save_changes
      self
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.state = :deleted if self.state != :deleted
      self.deleted_at ||= Time.now
      self.save
    end

    def uri
      self.backup_storage.base_uri + self.object_key
    end
  end
end
