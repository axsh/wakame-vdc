# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancerInbound < AccountResource

    class RequestError < RuntimeError; end

    many_to_one :load_balancer
    subset(:alives, {:deleted_at => nil})

    def validate
      validates_includes LoadBalancer::SUPPORTED_PROTOCOLS, :protocol
      validates_includes 0..65535, :port
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.is_deleted = self.id
      self.save_changes
    end

  end
end
