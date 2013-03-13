# -*- coding: utf-8 -*-

# require 'dcmgr/endpoints/12.03/responses/dc_network'

module Dcmgr::Endpoints::V1203::Responses
  class IpPool < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::IpPool)
      @object = object
    end

    def generate()
      @object.instance_exec {
        { :id => self.canonical_uuid,
          :display_name => self.display_name,
        }
      }
    end
  end

  class IpPoolCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        IpPool.new(i).generate
      }
    end
  end

end
