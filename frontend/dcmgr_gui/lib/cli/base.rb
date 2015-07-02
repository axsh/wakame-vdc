# -*- coding: utf-8 -*-

require 'thor'

module Cli
  class Base < Thor
    protected
    def self.basename
      "#{super()} #{namespace}"
    end

    def add(model,options)
      raise ArgumentError unless options.is_a? Hash
      #TODO: Make this check a little tighter by checking that the model is either from the wakame backend or frontend
      UnknownModelError.raise(model) unless model < Sequel::Model

      fields = options.dup

      if fields.has_key?("uuid") || fields.has_key?(:uuid)
        fields[:uuid] = model.trim_uuid(fields[:uuid]) if model.check_uuid_format(fields[:uuid])
      end

      #Create database fields
      new_record = model.create(fields)

      #Return uuid if there is one
      new_record.canonical_uuid #if model.respond_to? "canonical_uuid"
    end

    def del(model,uuid)
      UnknownModelError.raise(model) unless model < Sequel::Model
      to_delete = model[uuid] || UnknownUUIDError.raise(uuid)
      to_delete.destroy
    end

    def modify(model,uuid,fields)
      UnknownModelError.raise(model) unless model < Sequel::Model
      raise ArgumentError unless fields.is_a? Hash
      to_modify = model[uuid] || UnknownUUIDError.raise(uuid)

      #Use a copy of the fields hash so this method can work with frozen hashes
      fields_nonil = fields.merge({})
      #Don't update empty fields
      fields_nonil.delete_if {|key,value| value.nil?}

      to_modify.set(fields_nonil)
      to_modify.updated_at = Time.now.utc.iso8601 if to_modify.with_timestamps?
      to_modify.save_changes
    end
  end
end
