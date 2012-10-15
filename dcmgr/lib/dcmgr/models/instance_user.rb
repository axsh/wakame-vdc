# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceUser < AccountResource
    taggable 'iuser'

    many_to_one :instance

    def validate
      # do not run validation if the row is maked as deleted.
      return true if self.deleted_at

      super
    end

    # Hash data for API response.
    def to_api_document
      h = {
        :id => self.canonical_uuid,
        :uuid => self.canonical_uuid,
        :instance_id => (self.instance && self.instance.canonical_uuid),
        :username => self.username,
        :encrypted_password => self.encrypted_password,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :deleted_at => self.deleted_at,
      }
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.save
    end

  end
end
