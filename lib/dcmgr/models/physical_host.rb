module Dcmgr
  module Models
    class PhysicalHost < Sequel::Model
      include Base
      def self.prefix_uuid; 'PH'; end

      one_to_many :hv_agents
      
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_PHYSICAL_HOST}
      many_to_many :location_tags, :class=>:Tag, :right_key=>:tag_id, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_PHYSICAL_HOST_LOCATION}

      many_to_one :relate_user, :class=>:User

      def self.enable_hosts
        filter(~:id => TagMapping.filter(:target_type=>TagMapping::TYPE_PHYSICAL_HOST).select(:target_id)).order_by(:id).all
      end

      def self.assign(instance)
        Dcmgr::scheduler.assign_to_instance(enable_hosts, instance)
      end
      
      def before_create
        super
      end

      def after_create
        super
        TagMapping.create(:tag_id=>Tag.system_tag(:STANDBY_INSTANCE).id,
                          :target_type=>TagMapping::TYPE_PHYSICAL_HOST,
                          :target_id=>self.id)
      end

      def instances
        self.hv_agents.map{|hva| hva.instances}.flatten
      end

      def create_location_tag(name, account)
        TagMapping.create(:tag_id=>Tag.create(:name=>name, :account=>account).id,
                          :target_type=>TagMapping::TYPE_PHYSICAL_HOST_LOCATION,
                          :target_id=>self.id)
      end

      def space_cpu_mhz
        setup_space unless @space_cpu_mhz
        @space_cpu_mhz
      end

      def setup_space
        
        need_cpu_mhz = instances.inject(0) {|v, ins| v + ins.need_cpu_mhz}
        space_cpu_mhz = cpu_mhz - need_cpu_mhz
        # 10 % down
        @space_cpu_mhz = space_cpu_mhz * 0.9
        
        need_memory = instances.inject(0) {|v, ins| v + ins.need_memory}
        space_memory = memory - need_memory
        # 10 % down
        @space_memory = space_memory * 0.9
      end
      
      def space_memory
        setup_space unless @space_memory
        @space_memory
      end
    end
  end
end
