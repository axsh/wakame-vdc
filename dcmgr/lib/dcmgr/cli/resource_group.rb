# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class ResourceGroup < Base
    namespace :resourcegroup
    M = Dcmgr::Models
    T = Dcmgr::Tags

    TYPES={"network"=>:NetworkGroup, "host"=>:HostNodeGroup, "storage"=>:StorageNodeGroup}.freeze

    no_tasks {
      def self.common_options
        method_option :uuid, :type => :string, :desc => "The UUID for the new resource group"
        method_option :account_id, :type => :string, :desc => "The UUID of the account that this resource group belongs to"
        method_option :name, :type => :string, :desc => "The name for the new resource group"
        method_option :attributes, :type => :string, :desc => "The attributes for the new resource group"
      end
    }

    desc "add [options]", "Create a new resource group"
    common_options
    # type field can not be modified.
    method_option :type, :type => :string, :desc => "The type for the new resource group. Valid types are [#{TYPES.keys.join(", ")}]", :required => true
    method_options[:account_id].required = true
    method_options[:name].required = true
    def add
      Error.raise("Invalid type: '#{options[:type]}'. Valid types are [#{TYPES.keys.join(", ")}].",100) unless TYPES.member? options[:type]

      fields = options.dup.tap {|h| h.delete(:type)}

      puts super(eval("T::#{TYPES[options[:type]]}"),fields)
    end

    desc "modify UUID [options]", "Modify an existing resource group"
    common_options
    def modify(uuid)
      tag = M::Taggable.find(uuid)
      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag

      super(tag.class,uuid,options)
    end

    desc "show [UUID]", "Show the existing resource groups"
    method_option :type, :type => :string, :desc => "Show only the groups of a single type. Valid types are [#{TYPES.keys.join(", ")}]"
    def show(uuid=nil)
      if uuid
        tag = M::Taggable.find(uuid)
        UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag

        puts ERB.new(<<__END, nil, '-').result(binding)
Group UUID:
  <%= tag.canonical_uuid %>
Account id:
  <%= tag.account_id %>
Name:
  <%= tag.name %>
Type:
  <%= TYPES.invert[Dcmgr::Constants::Tag::KEY_MAP[tag.type_id]] %>
Mapped uuids:
<%- tag.sorted_mapped_uuids.each { |tagmap| -%>
  <%= tagmap[:uuid] %> <%= tagmap[:sort_index] %>
<%- } -%>
Attributes:
  <%= tag.attributes %>
__END
      else
        tags = if options[:type]
          Error.raise("Invalid type: '#{options[:type]}'. Valid types are [#{TYPES.keys.join(", ")}].",100) unless TYPES.member? options[:type]
          Dcmgr::Tags.const_get(TYPES[options[:type]])
        else
          M::Tag
        end

        puts ERB.new(<<__END, nil, '-').result(binding)
<%- tags.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= TYPES.invert[Dcmgr::Constants::Tag::KEY_MAP[row.type_id]] %>\t<%= row.name%>
<%- } -%>
__END
      end
    end

    desc "del UUID", "Delete an existing resource group"
    def del(uuid)
      tag = M::Taggable.find(uuid)
      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      tag.remove_all_mapped_uuids
      super(tag.class,uuid)
    end

    desc "map UUID OBJECT_UUID", "Add a resource to a group"
    long_desc <<__DESC
Add a resource to a group.

 UUID: Resource group canonical UUID.
 OBJECT_UUID: The canonical UUID represents the object to label this resource group.
__DESC
    method_option :sort_index, :type => :numeric, :default => 0, :desc => "An arbitrary number that can optionally be used to sort the resources in this group"
    def map(uuid, object_uuid)
      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants(false).each {|c| M.const_get(c, false) }

      object = M::Taggable.find(object_uuid)
      tag    = M::Taggable.find(uuid)

      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      UnknownUUIDError.raise(object_uuid) if object.nil?
      Error.raise("A '#{object.class}' can not be put into #{uuid}.",100) unless tag.accept_mapping?(object)

      tag.map_resource(object,options[:sort_index])
    end

    desc "index UUID OBJECT_UUID INDEX", "Set the sort index for a resource in a group"
    def index(uuid, object_uuid, index)
      # Check index format
      is_numeric = !!Integer(index) rescue false
      if is_numeric
        index = index.to_i
      else
        Error.raise("'#{index}' is not a valid index. Must be numeric.",100)
      end

      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants(false).each {|c| M.const_get(c, false) }

      group    = M::Taggable.find(uuid)
      resource = M::Taggable.find(object_uuid)

      UnknownUUIDError.raise(uuid) unless group.is_a? M::Tag
      UnknownUUIDError.raise(object_uuid) if resource.nil?
      Error.raise("A '#{resource.class}' can not be put into #{uuid}.",100) unless group.accept_mapping?(resource)

      mapping = M::TagMapping.find(
        :tag_id => group.id,
        :uuid   => resource.canonical_uuid
      )

      mapping.set({:sort_index => index})
      mapping.save
    end

    desc "unmap UUID OBJECT_UUID", "Remove a resource from a group"
    long_desc <<__DESC
"Remove a resource from a group".

 UUID: Resource group canonical UUID.
 OBJECT_UUID: The canonical UUID represents the object to label this resource group.
__DESC
    def unmap(uuid, object_uuid)
      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants(false).each {|c| M.const_get(c, false) }

      object = M::Taggable.find(object_uuid)
      tag    = M::Taggable.find(uuid)

      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      UnknownUUIDError.raise(object_uuid) if object.nil?
      Error.raise("A '#{object.class}' can not be put into #{uuid}.",100) unless tag.accept_mapping?(object)

      mapping = M::TagMapping.find(
        :tag_id => tag.id,
        :uuid   => object.canonical_uuid
      )

      raise "#{object.canonical_uuid} does not exist in #{tag.canonical_uuid}" if mapping.nil?
      mapping.destroy
    end
  end
end
