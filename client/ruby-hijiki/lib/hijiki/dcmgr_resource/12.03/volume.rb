# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Volume < Base

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def list(params = {})
        super(params.merge({:state=>'alive_with_deleted'}))
      end

      def create(params)
        volume = self.new
        volume.volume_size = params[:volume_size]
        volume.backup_object_id = params[:backup_object_id]
        volume.display_name = params[:display_name]
        volume.save
        volume
      end

      def destroy(volume_id)
        self.delete(volume_id).body
      end

      def update(volume_id, params)
	self.put(volume_id,params).body
      end

      def attach(volume_id, instance_id)
        result = self.find(volume_id).put(:attach, {:instance_id => instance_id})
        result.body
      end

      def detach(volume_id)
        result = self.find(volume_id).put(:detach)
        result.body
      end

      def status(account_id)
        result = self.find(account_id).get(:status)
        result
      end

      def backup(volume_id, params={})
        params = params.select {|k,v| [:display_name, :description].member?(k.to_sym) }
        result = self.find(volume_id).put(:backup, params)
        result.body
      end
    end
    extend ClassMethods

  end
end
