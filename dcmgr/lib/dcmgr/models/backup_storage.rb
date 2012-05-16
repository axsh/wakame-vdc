# -*- coding: utf-8 -*-

module Dcmgr::Models
  class BackupStorage < BaseNew
    taggable 'bkst'

    STORAGE_TYPES=[:local, :webdav].freeze

    def validate
      unless STORAGE_TYPES.member?(self.storage_type.to_sym)
        errors.add(:storage_type, "Unknown storage type: #{self.storage_type}")
      end
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.save
    end
  end
end
