# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class LoadBalancer < Base
    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def create(params)
        lb = self.new
        lb.instance_spec_id = params[:instance_spec_id]
        lb.display_name = params[:display_name]
        lb.protocol = params[:protocol]
        lb.port = params[:port]
        lb.instance_protocol = params[:instance_protocol]
        lb.instance_port = params[:instance_port]
        lb.balance_algorithm = params[:balance_algorithm]
        lb.private_key = params[:private_key]
        lb.public_key = params[:public_key]
        lb.cookie_name = params[:cookie_name]
        lb.description = params[:description]
        lbs = LoadBalancerSpec.show(params[:load_balancer_spec_id]) || raise("Unknown load balancer spec: #{params[load_balancer_spec_id]}")
        lb.max_connection = lbs.max_connection
        lb.engine = lbs.engine
        lb.save
        lb
      end

      def list(params = {})
        self.find(:all,:params => params.merge({:state=>'alive_with_deleted'}))
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

      def register(load_balancer_id, vifs)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection, load_balancer_id)
        result = self.put(:register, {:load_balancer_id => load_balancer_id, :vifs => vifs})
        self.collection_name = @collection
        result.body
      end

      def unregister(load_balancer_id, vifs)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection, load_balancer_id)
        result = self.put(:unregister, {:load_balancer_id => load_balancer_id, :vifs => vifs})
        self.collection_name = @collection
        result.body
      end

      def poweron(load_balancer_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection, load_balancer_id)
        result = self.put(:poweron, {:load_balancer_id => load_balancer_id})
        self.collection_name = @collection
        result.body
      end

      def poweroff(load_balancer_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection, load_balancer_id)
        result = self.put(:poweroff, {:load_balancer_id => load_balancer_id})
        self.collection_name = @collection
        result.body
      end

      def update(load_balancer_id,params)
        self.put(load_balancer_id,params).body
      end
    end
    extend ClassMethods

  end
end
