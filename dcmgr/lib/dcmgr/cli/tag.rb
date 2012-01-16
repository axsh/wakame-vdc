# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Tag < Base
    namespace :tag
    M = Dcmgr::Models

    desc "add [options]", "Create a new tag"
    method_option :uuid, :type => :string, :desc => "The UUID for the new tag"
    method_option :account_id, :type => :string, :desc => "The UUID of the account that this tag belongs to", :required => true
    method_option :type_id, :type => :numeric, :desc => "The type for the new tag. Valid types are '#{Dcmgr::Tags::KEY_MAP.keys.join(", ")}'", :required => true
    method_option :name, :type => :string, :desc => "The name for the new tag", :required => true
    method_option :attributes, :type => :string, :desc => "The attributes for the new tag"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      Error.raise("Invalid type_id: '#{options[:type_id]}'. Valid types are '#{Dcmgr::Tags::KEY_MAP.keys.join(", ")}'.",100) unless Dcmgr::Tags::KEY_MAP.member? options[:type_id]
      
      puts super(M::Tag,options)
    end
    
    desc "modify UUID [options]", "Modify an existing tag"
    method_option :account_id, :type => :string, :desc => "The UUID of the account that this tag belongs to"
    method_option :type_id, :type => :numeric, :desc => "The type for the new tag. Valid types are '#{Dcmgr::Tags::KEY_MAP.keys.join(", ")}'"
    method_option :name, :type => :string, :desc => "The name for the new tag"
    method_option :attributes, :type => :string, :desc => "The attributes for the new tag"
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?
      Error.raise("Invalid type_id: '#{options[:type_id]}'. Valid types are '#{Dcmgr::Tags::KEY_MAP.keys.join(", ")}'.",100) unless options[:type_id].nil? || Dcmgr::Tags::KEY_MAP.member?(options[:type_id])
      super(M::Tag,uuid,options)
    end
    
    desc "show [UUID]", "Show the existing tag(s)"
    def show(uuid=nil)
      if uuid
        tag = M::Tag[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
Tag UUID:
  <%= tag.canonical_uuid %>
Account id:
  <%= tag.account_id %>
Name:
  <%= tag.name %>
Type id:
  <%= tag.type_id %>
Attributes:
  <%= tag.attributes %>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::Tag.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= row.type_id %>\t<%= row.name%>
<%- } -%>
__END
      end
    end
    
    desc "del UUID", "Delete an existing tag"
    def del(uuid)
      super(M::Tag,uuid)
    end
    
    desc "map UUID OBJECT_UUID", "Map a tag to a taggable object"
    long_desc <<__DESC
Map a tag to a taggable object.

 UUID: Tag canonical UUID. 
 OBJECT_UUID: The canonical UUID represents the object to label this tag.
__DESC
    #method_option :object_id, :type => :string, :desc => "The canonical UUID for the object to map this tag to.", :required => true
    def map(uuid, object_uuid)
      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants.each {|c| M.const_get(c) }
      
      object = M::Taggable.find(object_uuid)

      UnknownUUIDError.raise(uuid) if M::Tag[uuid].nil?
      UnknownUUIDError.raise(object_uuid) if object.nil?
      Error.raise("Tag '#{uuid}' can not be mapped to a '#{object.class}'.",100) unless M::Tag[uuid].accept_mapping?(object)
      
      M::TagMapping.create(
        :tag_id => M::Tag[uuid].id,
        :uuid   => object.canonical_uuid
      )
    end
  end
end
