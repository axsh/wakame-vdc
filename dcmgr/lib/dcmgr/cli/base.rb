# -*- coding: utf-8 -*-

require 'thor'

module Dcmgr::Cli
  class Base < Thor
    protected
    def self.basename
      "#{super()} #{namespace}"
    end

    no_tasks {
      public
      # add before/after task hook.
      def invoke_task(task, *args)
        Dcmgr::Models::BaseNew.db.transaction do
          before_task
          super(task, *args)
          after_task
        end
      end
    
      protected
      def before_task
      end
      
      def after_task
      end
    }
    
    def add(model,options)
      raise ArgumentError unless options.is_a? Hash
      #TODO: Make this check a little tighter by checking that the model is either from the wakame backend or frontend
      #UnknownModelError.raise(model) unless model < Dcmgr::Models::BaseNew
      UnknownModelError.raise(model) unless model < Sequel::Model
      
      fields = options.dup
      
      if fields.has_key?("uuid") || fields.has_key?(:uuid)
        fields[:uuid] = model.trim_uuid(fields[:uuid]) if model.check_uuid_format(fields[:uuid])
        Error.raise("UUID syntax invalid: #{fields[:uuid]}",100) unless model.check_trimmed_uuid_format(fields[:uuid])
      end
      
      #Create database fields
      new_record = model.create(fields)
      
      #Return uuid if there is one
      new_record.canonical_uuid #if model.respond_to? "canonical_uuid"
    end
    
    def del(model,uuid)
      #UnknownModelError.raise(model) unless model < Dcmgr::Models::BaseNew
      UnknownModelError.raise(model) unless model < Sequel::Model
      to_delete = model[uuid] || UnknownUUIDError.raise(uuid)
      to_delete.destroy
    end
    
    def modify(model,uuid,fields)
      #UnknownModelError.raise(model) unless model < Dcmgr::Models::BaseNew
      UnknownModelError.raise(model) unless model < Sequel::Model
      raise ArgumentError unless fields.is_a? Hash
      to_modify = model[uuid] || UnknownUUIDError.raise(uuid)
      
      #Use a copy of the fields hash so this method can work with frozen hashes
      fields_nonil = fields.merge({})
      #Don't update empty fields
      fields_nonil.delete_if {|key,value| value.nil?}
      
      to_modify.set(fields_nonil)
      to_modify.save_changes
    end
  end
end
