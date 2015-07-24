# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenterInstance < BaseNew
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end
  end
end
