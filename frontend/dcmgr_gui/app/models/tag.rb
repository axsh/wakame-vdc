# -*- coding: utf-8 -*-
class Tag < BaseNew
  taggable('tag')
  with_timestamps
  plugin :single_table_inheritance, :type_id, :model_map=>{}
  plugin :subclasses
  
  inheritable_schema do
    primary_key :id, :type=>Integer
    Fixnum :account_id, :null=>false # if 0 system tag
    index :account_id
    Fixnum :owner_id, :null=>false
    String :name, :fixed=>true, :size=>32, :null=>false
  end

  TYPE_NORMAL = 0
  TYPE_AUTH = 1

  many_to_one :account
  
  #one_to_many :tag_mappings, :dataset=>proc{ TagMapping.dataset.filter(:tag_id=>self.id) } do
  one_to_many :mapped_uuids, :class=>TagMapping do |ds|
    ds.instance_eval {
      def exists?(canonical_uuid)
        !self.filter(:uuid=>canonical_uuid).empty?
      end
    }
    ds
  end

  class UnacceptableTagType < StandardError
    def initialize(msg, tag, taggable)
      super(msg)

      raise ArgumentError, "Expected #{Tag.class}: #{tag.class}"  unless tag.is_a?(Tag)
      raise ArgumentError, "Expected #{Taggable.class}: #{tag.class}"  unless taggable.is_a?(Taggable)
      @tag = tag
      @taggable = taggable
    end
    #TODO: show @tag and @taggable info to the error message.
  end
  class TagAlreadyLabeled < StandardError; end
  class TagAlreadyUnlabeled < StandardError; end

  def labeled?(canonical_uuid)
    # TODO: check if the uuid exists
    
    !TagMapping.filter(:uuid=>canonical_uuid, :tag_id=>self.pk).empty?
  end
  
  def label(canonical_uuid)
    tgt = Taggable.find(canonical_uuid)
    
    raise(UnacceptableTagType, self, tgt) if accept_mapping?(tgt)
    raise(TagAlreadyLabeled) if labeled?(canonical_uuid)
    TagMapping.create(:uuid=>canonical_uuid, :tag_id=>self.pk)
    self
  end

  def unlabel(canonical_uuid)
    t = TagMapping.find(:uuid=>canonical_uuid, :tag_id=>self.pk) || raise(TagAlreadyUnlabeled)
    t.delete
    self
  end
  
  #many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_TAG}
  
  #many_to_one :owner, :class=>:User
  
  #one_to_many :tag_attributes, :one_to_one=>true

  def self.find_tag_class(name)
    self.subclasses.find { |m|
      m.to_s.sub(/^#{self.class}::/, '') == name
    }
  end

  # STI class variable setter, getter methods.
  class << self
    
    # Declare the integer number for the tag.
    # 
    # Also set the value to sti map in class Tag.
    # class Tag1 < Tag
    #   type_id 123456
    # end
    # 
    # puts Tag1.type_id # == 123456
    def type_id(type_id=nil)
      if type_id.is_a?(Fixnum)
        @type_id = type_id
        Tag.sti_model_map[type_id] = self
        Tag.sti_key_map[self.to_s] = type_id
      end
      @type_id || raise("#{self}.type_id is unset. Please set the unique number for the tag instance.")
    end


    # Set or read description of the Tag class.
    def description(desc=nil)
      if desc
        @description = desc
      end
      @description
    end

  end

  # Check the object class type before associating to the Tag.
  # Child class must implement this method.
  # @param taggable_obj any object kind_of?(Model::Taggable)
  def accept_mapping?(taggable_obj)
    raise NotImplementedError 
  end

  def after_initialize
    super
    self[:type_id] = self.class.type_id
  end

end
