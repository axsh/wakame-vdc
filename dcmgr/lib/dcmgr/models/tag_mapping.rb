require 'sequel'

module Dcmgr
  module Models
    class TagMapping < Sequel::Model
      TYPE_ACCOUNT = 0
      TYPE_TAG = 1
      TYPE_USER = 2
      TYPE_INSTANCE = 3
      TYPE_INSTANCE_IMAGE = 4
      TYPE_HV_CONTROLLER = 5
      TYPE_HV_AGENT = 6
      TYPE_PHYSICAL_HOST = 7
      TYPE_PHYSICAL_HOST_LOCATION = 8
      TYPE_IMAGE_STORAGE_HOST = 9
      TYPE_IMAGE_STORAGE = 10
      
      many_to_one :tag

      def self.target_exist?(target_types, role_tag)
          dataset.where(:target_type=>target_types,
                        :tag_id=>role_tag.tags.map{|t| t.id},
                        :target_id=>0).count > 0
      end
    end
  end
end

