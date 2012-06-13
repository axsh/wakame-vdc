# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  module InstanceMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def create(params)
        instance = self.new
        instance.image_id = params[:image_id]
        instance.instance_spec_id = params[:instance_spec_id]
        instance.host_pool_id = params[:host_pool_id]
        instance.host_name = params[:host_name]
        instance.user_data = params[:user_data]
        instance.security_groups = params[:security_groups]
        instance.ssh_key_id = params[:ssh_key]
        instance.display_name = params[:display_name]

        instance.vifs = params[:vifs] if params[:vifs]

        instance.save
        instance
      end
      
      def destroy(instance_id)
        self.delete(instance_id).body
      end
      
      def reboot(instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,instance_id)
        result = self.put(:reboot)
        self.collection_name = @collection
        result.body
      end

      def start(instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,instance_id)
        result = self.put(:start)
        self.collection_name = @collection
        result.body
      end

      def stop(instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,instance_id)
        result = self.put(:stop)
        self.collection_name = @collection
        result.body
      end

      def update(instance_id,params)
        self.put(instance_id,params).body
      end
    end
  end

  class Instance < Base
    include Hijiki::DcmgrResource::ListMethods
    include InstanceMethods
  end
end
