# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class VirtualDataCenterSpec < Dcmgr::Endpoints::ResponseGenerator
    def initialize(virtual_data_center_spec)
      raise ArgumentError if !virtual_data_center_spec.is_a?(Dcmgr::Models::VirtualDataCenterSpec)
      @virtual_data_center_spec = virtual_data_center_spec
    end

    def generate()
      @virtual_data_center_spec.instance_exec {
        h = {
          :uuid => canonical_uuid,
          :account_id => account_id,
          :name => name,
          :file => file,
          :created_at => created_at,
          :updated_at => updated_at,
          :deleted_at => deleted_at,
        }

        h
      }
    end

  end

  class VirtualDataCenterSpecCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |vdc|
        VirtualDataCenterSpec.new(vdc).generate
      }
    end
  end

end
