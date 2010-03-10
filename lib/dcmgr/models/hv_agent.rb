module Dcmgr
  module Models
    class HvAgent < Base
      set_dataset :hv_agents
      def self.prefix_uuid; 'HVA'; end
      many_to_one :hv_controller
      many_to_one :physical_host
      one_to_many :instances
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_HV_AGENT}
    end
  end
end
