# -*- coding: utf-8 -*-

module Dcmgr::Models

  class Alarm < AccountResource
    taggable 'al'
    subset(:alives, {:deleted_at => nil})
    plugin :serialization, :yaml, :params

    def validate
    end

    def delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

    def self.entry_new(account, &blk)
      al = self.new
      al.account_id = (account.is_a?(Account) ? account.canonical_uuid : account.to_s)
      blk.call(al)
      al.save
    end
  end
end
