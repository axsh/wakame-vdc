
require 'sequel/model'

module Wakame
  module Models
    class ApplicationRepository < Sequel::Model
      plugin :schema
      plugin :hook_class_methods
      
      set_schema {
        primary_key :id, :type => Integer
        column :app_name, :varchar, :unique=>true
        column :repo_type, :varchar
        column :repo_uri, :varchar
        column :revision, :varchar
        column :resource_tag, :varchar
        column :options, :text
        column :comment, :text
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

  Initializer.loaded_classes << Models::ApplicationRepository if const_defined? :Initializer
end
