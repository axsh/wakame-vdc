# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenterSpec < BaseNew
    class YamlLoadError < StandardError; end
    class YamlFormatError < StandardError; end

    taggable 'vdcs'

    plugin :serialization

    serialize_attributes :yaml, :file

    def self.entry_new(account, spec_file)
      raise ArgumentError, "The account parameter must be an Account. Got '#{account.class}'" unless account.is_a?(Account)
      file = check_spec_file_format(load(spec_file))
      vdcs = self.new
      vdcs.account_id = account.canonical_uuid
      vdcs.name = file['vdc_name']
      vdcs.file = file
      vdcs.save
      vdcs
    end

    def self.load(spec_file)
      raise ArgumentError, "The spec_file parameter must be a String. Got '#{spec_file.class}'" if !spec_file.is_a?(String)
      vdc_spec = begin
                   YAML.load(spec_file)
                 rescue Psych::SyntaxError
                   raise YamlLoadError, 'The spec_file parameter must be a yaml format.'
                 end

      vdc_spec
    end

    def self.check_spec_file_format(spec_file)

      f = spec_file
      errors = {}

      errors.store('vdc_name', 'required parameter.') if f['vdc_name'].nil?
      errors.store('instance_spec', 'required parameter.') if f['instance_spec'].nil?
      errors.store('vdc_spec', 'required parameter.') if f['vdc_spec'].nil?
      raise YamlFormatError, "#{errors.inspect}" if errors.length > 0

      spec_file
    end

    def instance_capacity
      instance_spec = self.spec_file['instance_spec'][self.spec]
      instance_count = self.spec_file['vdc_spec'].select { |k,v|
        v['instance_type'] == self.type && v['instance_spec'] == self.spec
      }.count

      (instance_spec['quota_weight'].to_i * instance_count)
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

    def generate_instance_params
      instance_params = []
      self.file['vdc_spec'].each { |k, v|
        instance_params << {
          'image_id' => v['image_id'],
          'ssh_key_id' => v['ssh_key_id'],
          'vifs' => v['vifs'],
          'user_data' => YAML.dump(v['user_data']),
        }.merge(self.file['instance_spec'][v['instance_spec']])
      }

      instance_params
    end
  end
end
