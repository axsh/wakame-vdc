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
  end
end
