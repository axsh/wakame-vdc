# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class ResourceLabel < Dcmgr::Endpoints::ResponseGenerator
    def initialize(resource_label)
      raise ArgumentError if !resource_label.is_a?(Dcmgr::Models::ResourceLabel)
      @resource_label = resource_label
    end

    def generate()
      @resource_label.instance_exec {
        h = {
          :uuid => self.resource_uuid,
          :name => self.name,
          :value_type => self.value_type,
          :value => self.value,
          :created_at => self.created_at,
          :updated_at => self.updated_at,
        }
      }
    end
  end

  class ResourceLabelCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        ResourceLabel.new(i).generate
      }
    end
  end
end
