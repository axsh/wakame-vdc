# -*- coding: utf-8 -*-

module Dcmgr::Models
  class BackupObject < AccountResource
    taggable 'bo'
    accept_service_type

    many_to_one :backup_storage
    plugin ArchiveChangedColumn, :histories

    subset(:alives, {:deleted_at => nil})
    
    class RequestError < RuntimeError; end

    def self.entry_new(account, size, &blk)
      bo = self.new
      bo.account_id = account.canonical_uuid
      bo.size = size.to_i
      bo.state = :creating
      blk.call(bo)
      bo.object_key ||= bo.canonical_uuid
      bo
    end
    
    def self.entry_delete(uuid)
      bo = self[uuid]
      if bo.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      bo.state = :deleting
      bo.save_changes
      bo
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.state = :deleted if self.state != :deleted
      self.deleted_at ||= Time.now
      self.save
    end
  end
end
