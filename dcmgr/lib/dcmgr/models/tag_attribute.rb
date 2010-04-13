require 'sequel'

module Dcmgr
  module Models
    class TagAttribute < Sequel::Model
      set_dataset :tag_attributes
      many_to_one :tag, :one_to_one=>true
      set_primary_key :tag_id
    end
  end
end

