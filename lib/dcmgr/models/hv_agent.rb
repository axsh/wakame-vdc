module Dcmgr
  module Models
    class HvAgent < Base
      set_dataset :hv_agents
      set_prefix_uuid 'HVA'

      many_to_one :hv_controller
      many_to_one :physical_host
      one_to_many :instances
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_HV_AGENT}
    end
  end
end
