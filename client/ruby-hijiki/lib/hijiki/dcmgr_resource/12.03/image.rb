# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Image < Base
    initialize_user_result nil, [:uuid,
                                 :account_id,
                                 :boot_dev_type,
                                 :arch,
                                 :description,
                                 :is_public,
                                 :state,
                                 :features,
                                 :file_format,
                                 :root_device,
                                 :is_cacheable,
                                 :service_type,
                                 :display_name,
                                 :backup_object_id,
                                 :created_at,
                                 :updated_at,
                                 :deleted_at,
                                ]

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def list(params = {})
        super({:state=>'alive_with_deleted', :is_public=>true}.merge(params))
      end

      def update(uuid,params)
        self.put(uuid,params).body
      end

      def destroy(uuid)
        self.delete(uuid).body
      end
    end
    extend ClassMethods
  end
end
