# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Tag < Base
    namespace :tag
    M = Dcmgr::Models

    desc "add [options]", "Create a new vlan lease."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new tag."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account that this tag belongs to.", :required => true
    method_option :type_id, :type => :numeric, :aliases => "-t", :desc => "The type for the new tag.", :required => true
    method_option :name, :type => :string, :aliases => "-n", :desc => "The name for the new tag.", :required => true
    method_option :attributed, :type => :string, :aliases => "-at", :desc => "The attributes for the new tag."
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      Error.raise("Invalid type_id: '#{options[:type_id]}'. Valid types are '#{Dcmgr::Tags::KEY_MAP.keys.join(", ")}'.",100) unless Dcmgr::Tags::KEY_MAP.member? options[:type_id]
      
      puts super(M::Tag,options)
    end
    
    desc "map UUID [options]", "Map a tag to a taggable object."
    method_option :object_id, :type => :string, :aliases => "-o", :desc => "The canonical UUID for the object to map this tag to.", :required => true
    def map(uuid)
      #Quick hack to get all models in Dcmgr::Models loaded in Taggable.uuid_prefix_collection
      #This is so the Taggable.find method can be used to determine the Model class based on canonical uuid
      M.constants.each {|c| eval("M::#{c}")}
      
      object = M::Taggable.find(options[:object_id])

      UnknownUUIDError.raise(uuid) if M::Tag[uuid].nil?
      UnknownUUIDError.raise(options[:object_id]) if object.nil?
      Error.raise("Tag '#{uuid}' can not be mapped to a '#{object.class}'.",100) unless M::Tag[uuid].accept_mapping?(object)
      
      M::TagMapping.create(
        :tag_id => M::Tag[uuid].id,
        :uuid   => object.canonical_uuid
      )
    end
  end
end
