# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class SecurityGroup < Dcmgr::Endpoints::ResponseGenerator
    def initialize(security_group)
      raise ArgumentError if !security_group.is_a?(Dcmgr::Models::SecurityGroup)
      @security_group = security_group
    end

    def generate()
      @security_group.instance_exec {
        to_hash.merge(:id=>canonical_uuid, :labels=>resource_labels.map{ |l| ResourceLabel.new(l).generate })
      }
    end
  end

  class SecurityGroupCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        SecurityGroup.new(i).generate
      }
    end
  end
end
