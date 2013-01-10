# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Tag is a label which groups arbitrary resource(s) having canonical
  # uuid. A tag object consists of three items: Account ID, Type, Name
  #
  # Account ID is top level scope that represents the owner of the
  # tag. Each tag instance is created in the scope of the account.
  #
  # Type field is second level scope to filter the object out to be
  # labeled. If the tag is only for grouping resource A, it will fail
  # at labling the tag other than resource A.
  #
  # Name represents the instance ID of the tag. This is a string that
  # must be unique in the scope of Account ID and Type.
  # Below is Type & Name matrix in single account:
  # TypeA, name1
  # TypeA, name1 # can not create
  # TypeB, name2 # ok
  # TypeB, name1 # nop
  #
  # The resource can be labeled is called "Taggable" resource. The
  # model framework is provided to declare simply.
  #
  # class A < Dcmgr::Models::Base
  #   taggable 'xxx'
  # end
  #
  # @example Retrieve tag
  # t = Tag.declare(account_id, :NetworkGroup, 'xxxxx')
  # t.mapped_uuids # => ['nw-11111', 'nw-22222' ,'nw-33333']
  #
  # @example Lable a tag from tag
  # t = Tag.declare(account_id, :NetworkGroup, 'nwgroup1')
  # t.lable('nw-xxxxx')
  # t.lable('nw-yyyyy')
  #
  # @example Label a tag from resource
  # t = Tag.declare(account_id, :NetworkGroup, 'nwgroup1')
  # nw = Network['nw-44444']
  # nw.label_tag(t)
  # nw.label_tag('tag-xxxxx')
  class Tag < AccountResource
    taggable('tag')

    many_to_one :account

    one_to_many :mapped_uuids, :class=>TagMapping do |ds|
      ds.instance_eval {
        def exists?(canonical_uuid)
          !self.filter(:uuid=>canonical_uuid).empty?
        end
      }
      ds
    end

    def map_resource(resource, sort_index = 0)
      raise "This tag can not map resources of type #{resource.class}" unless self.accept_mapping?(resource)

      TagMapping.create(
        :tag_id => self.id,
        :uuid   => resource.canonical_uuid,
        :sort_index => sort_index
      )
    end

    def self.mappable(resource=nil)
      resource && @mappable = resource

      @mappable
    end

    def accept_mapping?(to)
      to.is_a?(self.class.mappable)
    end

    def sorted_mapped_uuids_dataset
      self.mapped_uuids_dataset.order_by(:sort_index)
    end

    def sorted_mapped_uuids
      sorted_mapped_uuids_dataset.all
    end

    def mapped_resources_dataset
      resource = self.class.mappable

      trimmed_uuids = self.mapped_uuids.map {|mapping| resource.trim_uuid(mapping.uuid) }
      resource.dataset.filter(:uuid => trimmed_uuids)
    end

    def mapped_resources
      mapped_resources_dataset.all
    end

    # sti plugin has to be loaded at lower position.
    plugin :subclasses
    plugin :single_table_inheritance, :type_id,
         :key_map=>proc {|v| Dcmgr::Constants::Tag::MODEL_MAP[v.to_s.split('Dcmgr::Tags::').last.to_sym] },
         :model_map=>proc {|v| Dcmgr::Tags.const_get(Dcmgr::Constants::Tag::KEY_MAP[v], false) }

    class UnacceptableTagType < StandardError
      def initialize(msg, tag, taggable)
        super(msg)

        raise ArgumentError, "Expected child of #{Tag} but #{tag.class}"  unless tag.is_a?(Tag)
        raise ArgumentError, "Expected kind of #{Taggable} but #{taggable.class}"  unless taggable.kind_of?(Taggable)
        @tag = tag
        @taggable = taggable
      end
      #TODO: show @tag and @taggable info to the error message.
    end
    class TagAlreadyLabeled < StandardError; end
    class TagAlreadyUnlabeled < StandardError; end

    def labeled?(canonical_uuid)
      # TODO: check if the uuid exists

      !TagMapping.filter(:tag_id=>self.pk, :uuid=>canonical_uuid).empty?
    end

    # Associate the tag to the taggable object.
    #
    # @params [Models::Taggable,String] taggable_or_uuid
    def label(taggable_or_uuid)
      tgt = case taggable_or_uuid
            when String
              Taggable.find(taggable_or_uuid)
            when Models::Taggable
              taggable_or_uuid
            else
              raise TypeError
            end

      raise(UnacceptableTagType.new("", self, tgt)) unless accept_mapping?(tgt)
      raise(TagAlreadyLabeled) if labeled?(tgt.canonical_uuid)
      TagMapping.create(:uuid=>tgt.canonical_uuid, :tag_id=>self.pk)
      self
    end

    def lable_ifnot(t)
      begin
        lable(t)
      rescue TagAlreadyLabeled
      end
      self
    end

    # Disassociate the tag from the taggable object.
    #
    # @params [Models::Taggable,String] taggable_or_uuid
    def unlabel(taggable_or_uuid)
      tgt = case taggable_or_uuid
            when String
              Taggable.find(taggable_or_uuid) || raise("Not found Taggable object: #{taggable_or_uuid}")
            when Models::Taggable
              taggable_or_uuid
            else
              raise TypeError
            end
      t = TagMapping.find(:tag_id=>self.pk, :uuid=>tgt.canonical_uuid) || raise(TagAlreadyUnlabeled)
      t.destroy
      self
    end

    def self.find_tag_class(name)
      self.subclasses.find { |m|
        m == name || m.split('::').last == name
      }
    end

    # model hook
    def before_destroy
      return false if !mapped_uuids_dataset.empty?
      super
    end

    def self.lock!
      super
      TagMapping.lock!
    end

    def to_api_document
      to_hash.merge({:type_id=>self.class.to_s.split('::').last})
    end
  end
end
