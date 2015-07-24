# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenterSpec < BaseNew
    plugin :serialization

    serialize_attributes :yaml, :spec

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end
  end
end
