module Dcmgr
  module Models
    class Tag <  Base
      set_dataset :tags
      def self.prefix_uuid; 'TAG'; end

      TYPE_NORMAL = 0
      TYPE_AUTH = 1

      many_to_one :account

      one_to_many :tag_mappings
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_TAG}

      many_to_one :owner, :class=>:User

      one_to_many :tag_attributes, :one_to_one=>true

      def self.create_system_tag(name)
        create(:account_id=>0, :owner_id=>0,
               :role=>0, :name=>name)
      end

      def initialize(*args)
        @attribute = nil
        super
      end
      
      def self.create_system_tags
        SYSTEM_TAG_NAMES.each{|tag_name|
          create_system_tag(tag_name)
        }
      end

      def self.system_tag(name)
        tag_name = name.to_s.tr('_', ' ').downcase
        key = SYSTEM_TAG_NAMES.index(tag_name)
        unless key
          raise "unkown system tag: %s" % tag_name
        end
        Tag[key + 1]
      end

      def hash
        self.id
      end

      def eql?(obj)
        return false if obj == nil
        return false unless obj.is_a? Tag
        self.id.eql? obj.id
      end

      def ==(obj)
        return false if obj == nil
        return false unless obj.is_a? Tag
        self.id == obj.id
      end

      def role=(val)
        attribute = find_attribute
        attribute.role = val
      end

      def role
        attribute = find_attribute
        attribute.role
      end

      def save
        super
        if @attribute
          @attribute.tag_id = self.id unless @attribute.tag_id
          @attribute.save
        end
        self
      end

      def find_attribute
        return @attribute if @attribute
        
        if self.id
          unless @attribute = TagAttribute[:tag_id=>self.id]
            @attribute = TagAttribute.create(:tag_id=>self.id)
          end
        else
          @attribute = TagAttribute.new
        end

        @attribute
      end
      
      def validate
        errors.add(:name, "can't empty") if self.name == nil or self.name.length == 0
      end
      
      SYSTEM_TAG_NAMES = ['standby instance',
                          'wakame image',
                         ]
    end
  end
end
