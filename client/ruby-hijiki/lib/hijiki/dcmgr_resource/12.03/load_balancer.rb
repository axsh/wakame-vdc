# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  module LoadBalancerMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def list(params = {})
        data = self.find(:all, :params => params)
      end

      def show(uuid)
        self.get(uuid)
      end

      def destroy(load_balancer_id)
        self.delete(load_balancer_id).body
      end

      def status(account_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.get(:status)
        self.collection_name = @collection
        result
      end
    end
  end

  class LoadBalancer < Base
    include Hijiki::DcmgrResource::ListMethods
    include LoadBalancerMethods
  end
end
