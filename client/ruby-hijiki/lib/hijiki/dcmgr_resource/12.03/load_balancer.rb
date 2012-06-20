# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class LoadBalancer < Base

    module ClassMethods
      def list(params = {})
        data = self.find(:all, :params => params.merge({:state=>'alive_with_deleted'}))
      end

      def show(uuid)
        self.get(uuid)
      end

      def destroy(load_balancer_id)
        self.delete(load_balancer_id).body
      end

      def status(account_id)
        self.find(account_id).get(:status)
      end
    end
    extend ClassMethods

  end
end
