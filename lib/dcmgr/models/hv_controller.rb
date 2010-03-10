module Dcmgr
  module Models
    class HvController < Base
      set_dataset :hv_controllers
      def self.prefix_uuid; 'HVC'; end
      many_to_one :physical_host
      one_to_many :hv_agents
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_HV_CONTROLLER}
    end
  end
end
