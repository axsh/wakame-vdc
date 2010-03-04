module Dcmgr
  module Models
    class ImageStorage < Sequel::Model
      include Base
      def self.prefix_uuid; 'IS'; end
      
      many_to_one :image_storage_host
      
      many_to_one :account
      many_to_one :user
      
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_IMAGE_STORAGE}
    end
  end
end
