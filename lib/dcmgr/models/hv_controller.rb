module Dcmgr
  module Models
    class HvController < Base
      set_dataset :hv_controllers
      set_prefix_uuid 'HVC'
      
      one_to_many :hv_agents
      many_to_many :tags, :join_table=>:tag_mappings,
        :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_HV_CONTROLLER}

      def validate
        errors.add(:access_url, "can't empty") unless self.access_url
      end
    end
  end
end
