# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancerTarget < AccountResource
    class RequestError < RuntimeError; end

    def validate
      validates_includes ['on', 'off'], :fallback_mode
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.is_deleted = self.id
      self.save_changes
    end
  end
end
