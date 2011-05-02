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
        before_task
        super(task, *args)
        after_task
      end
    
      protected
      def before_task
      end
      
      def after_task
      end
    }
    
    def add(model,fields)
      raise ArgumentError unless fields.is_a? Hash
      #TODO: Check if model is a Sequel::Model
      #raise ArgumentError unless model.is_a? Sequel::Model
      
      if fields.has_key? :uuid
        trimmed_id = model.trim_uuid(fields[:uuid])
        Error.raise("UUID syntax invalid: #{fields[:uuid]}",100) unless model.check_trimmed_uuid_format(trimmed_id)
        fields[:uuid] = trimmed_id
      end
      
      #Create database fields
      new_record = model.create(fields)
      
      #Return uuid if there is one
      new_record.canonical_uuid #if model.respond_to? "canonical_uuid"
    end
    
    def del(model,uuid)
      to_delete = model[uuid] || UnknownUUIDError.raise(uuid)
      to_delete.destroy
    end
    
    def modify(model,uuid,fields)
      raise ArgumentError unless fields.is_a? Hash
      to_modify = model[uuid] || UnknownUUIDError.raise(uuid)
      
      #Use a copy of the fields hash so this method can work with frozen hashes
      fields_nonil = fields.merge({})
      #Don't update empty fields
      fields_nonil.delete_if {|key,value| value.nil?}
      
      to_modify.set(fields_nonil)
      to_modify.updated_at = Time.now if to_modify.with_timestamps?
      to_modify.save_changes
    end
  end
end
