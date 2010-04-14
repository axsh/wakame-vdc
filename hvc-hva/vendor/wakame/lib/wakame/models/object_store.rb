
require 'sequel/model'

module Wakame
  module Models
    class ObjectStore < Sequel::Model
      plugin :schema
      plugin :hook_class_methods

      unrestrict_primary_key

      set_schema {
        primary_key :id, :string, :size=>50, :auto_increment=>false
        column :class_type, :string
        column :dump, :text
        column :created_at, :datetime
        column :updated_at, :datetime
      }
      
      before_create(:set_created_at) do
        self.updated_at = self.created_at = Time.now
      end
      before_update(:set_updated_at) do
        self.updated_at = Time.now
      end

    end
  end

  Initializer.loaded_classes << Models::ObjectStore
end

