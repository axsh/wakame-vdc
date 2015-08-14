# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenterSpec < BaseNew
    plugin :serialization

    serialize_attributes :yaml, :spec_file

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

    def load(spec_file = nil)
      vdc_spec = if spec_file
                   raise ArgumentError, "The spec_file parameter must be a String. Got '#{spec_file.class}'" if !spec_file.is_a?(String)
                   begin
                     YAML.load(spec_file)
                   rescue Psych::SyntaxError
                     raise E::InvalidParameter, 'spec_file'
                   end
                 else
                   Dcmgr::Catalogs.virtualdatacenter.find_all
                 end
      vdc_spec
    end

    def generate_instance_params
      instance_spec = self.spec_file['instance_spec'][self.spec]
      vdc_spec = self.spec_file['vdc_spec'].select { |k, v|
        v['instance_type'] == self.type && v['instance_spec'] == self.spec
      }

      instance_params = []
      vdc_spec.each { |k, v|
        instance_params << {
          'image_id' =>  v['image_id'],
          'ssh_key_id' => v['ssh_key_id'],
          'vifs' => v['vifs'],
          'user_data' => YAML.dump(v['user_data']),
        }.merge(instance_spec)
      }

      instance_params
    end
  end
end
