# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class BackupObject < Base
    initialize_user_result nil, [:uuid,
                                 :state,
                                 :size,
                                 :allocation_size,
                                 :backup_storage_id,
                                 :object_key,
                                 :checksum,
                                 :progress,
                                 :description,
                                 :display_name,
                                 :service_type,
                                 :created_at,
                                 :updated_at,
                                 :deleted_at,
                                ]

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def list(params = {})
        super(params.merge({:state=>'alive_with_deleted'}))
      end

      def destroy(backup_object_id)
        self.delete(backup_object_id).body
      end

      def update(backup_object_id,params)
        self.put(backup_object_id,params).body
      end

      def status(account_id)
        self.find(account_id).get(:status)
      end
    end
    extend ClassMethods
  end
end
