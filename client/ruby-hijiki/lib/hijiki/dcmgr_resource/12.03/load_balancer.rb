# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class LoadBalancer < Base

    module ClassMethods
      def create(params)
        lb = self.new
        lb.instance_spec_id = params[:instance_spec_id]
        lb.display_name = params[:display_name]
        lb.protocol = params[:load_balancer_protocol]
        lb.port = params[:load_balancer_port]
        lb.instance_protocol = params[:instance_protocol]
        lb.instance_port = params[:instance_port]
        #lb.certificate_name = params[:certificate_name]
        #lb.private_key = params[:private_key]
        #lb.public_key = params[:public_key]
        #lb.certificate_chain = params[:certificate_chain]
        lb.cookie_name = params[:cookie_name]
        lb.save
        lb
      end

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
