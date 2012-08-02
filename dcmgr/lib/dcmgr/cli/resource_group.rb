# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class ResourceGroup < Base
    namespace :resourcegroup
    M = Dcmgr::Models
    T = Dcmgr::Tags

    TYPES={"network"=>:NetworkGroup, "host"=>:HostNodeGroup, "storage"=>:StorageNodeGroup}.freeze

    desc "add [options]", "Create a new tag"
    method_option :uuid, :type => :string, :desc => "The UUID for the new tag"
    method_option :account_id, :type => :string, :desc => "The UUID of the account that this tag belongs to", :required => true
    method_option :type, :type => :string, :desc => "The type for the new tag. Valid types are [#{TYPES.keys.join(", ")}]", :required => true
    method_option :name, :type => :string, :desc => "The name for the new tag", :required => true
    method_option :attributes, :type => :string, :desc => "The attributes for the new tag"
    def add
      Error.raise("Invalid type: '#{options[:type]}'. Valid types are [#{TYPES.keys.join(", ")}].",100) unless TYPES.member? options[:type]
      
      fields = options.dup.tap {|h| h.delete(:type)}
      
      puts super(eval("T::#{TYPES[options[:type]]}"),fields)
    end
    
    desc "modify UUID [options]", "Modify an existing tag"
    method_option :account_id, :type => :string, :desc => "The UUID of the account that this tag belongs to"
    method_option :name, :type => :string, :desc => "The name for the new tag"
    method_option :attributes, :type => :string, :desc => "The attributes for the new tag"
    def modify(uuid)
      tag = M::Taggable.find(uuid)
      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      
      super(tag.class,uuid,options)
    end
    
    desc "show [UUID]", "Show the existing tag(s)"
    def show(uuid=nil)
      if uuid
        tag = M::Taggable.find(uuid)
        UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
        
        puts ERB.new(<<__END, nil, '-').result(binding)
Tag UUID:
  <%= tag.canonical_uuid %>
Account id:
  <%= tag.account_id %>
Name:
  <%= tag.name %>
Type:
  <%= TYPES.invert[Dcmgr::Tags::KEY_MAP[tag.type_id]] %>
Mapped uuids:
<%- tag.mapped_uuids.each { |tagmap| -%>
  <%= tagmap[:uuid] %>
<%- } -%>
Attributes:
  <%= tag.attributes %>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::Tag.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= TYPES.invert[Dcmgr::Tags::KEY_MAP[row.type_id]] %>\t<%= row.name%>
<%- } -%>
__END
      end
    end
    
    desc "del UUID", "Delete an existing tag"
    def del(uuid)
      tag = M::Taggable.find(uuid)
      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      tag.remove_all_mapped_uuids
      super(tag.class,uuid)
    end
    
    desc "map UUID OBJECT_UUID", "Map a tag to a taggable object"
    long_desc <<__DESC
Map a tag to a taggable object.

 UUID: Tag canonical UUID. 
 OBJECT_UUID: The canonical UUID represents the object to label this tag.
__DESC
    def map(uuid, object_uuid)
      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants(false).each {|c| M.const_get(c, false) }
      
      object = M::Taggable.find(object_uuid)
      tag    = M::Taggable.find(uuid)

      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      UnknownUUIDError.raise(object_uuid) if object.nil?
      Error.raise("Tag '#{uuid}' can not be mapped to a '#{object.class}'.",100) unless tag.accept_mapping?(object)
      
      M::TagMapping.create(
        :tag_id => tag.id,
        :uuid   => object.canonical_uuid
      )
    end
    
    desc "unmap UUID OBJECT_UUID", "Unmap a tag from a taggable object"
    long_desc <<__DESC
Unmap a tag from a taggable object.

 UUID: Tag canonical UUID. 
 OBJECT_UUID: The canonical UUID represents the object to label this tag.
__DESC
    def unmap(uuid, object_uuid)
      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants(false).each {|c| M.const_get(c, false) }
      
      object = M::Taggable.find(object_uuid)
      tag    = M::Taggable.find(uuid)

      UnknownUUIDError.raise(uuid) unless tag.is_a? M::Tag
      UnknownUUIDError.raise(object_uuid) if object.nil?
      Error.raise("Tag '#{uuid}' can not be mapped to a '#{object.class}'.",100) unless tag.accept_mapping?(object)
      
      mapping = M::TagMapping.find(
        :tag_id => tag.id,
        :uuid   => object.canonical_uuid
      )
      
      raise "#{tag.canonical_uuid} is not mapped to #{object.canonical_uuid}" if mapping.nil?
      mapping.destroy
    end
  end
end
