module Dcmgr
  module Models
    class Account < Base
      set_dataset :accounts
      def self.prefix_uuid; 'A'; end
      
      many_to_many :users
      many_to_many :tags, :join_table=>:tag_mappings,
        :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_ACCOUNT}
      
      def before_create
        super
        self.created_at = Time.now unless self.created_at
      end
    end
  end
end
