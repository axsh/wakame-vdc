# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Tag < Dcmgr::Endpoints::ResponseGenerator
    def initialize(tag)
      raise ArgumentError, "Tag must be a #{Dcmgr::Models::Tag}" if !tag.is_a?(Dcmgr::Models::Tag)
      @tag = tag
    end

    def generate()
      @tag.instance_exec {
        to_hash.merge(
          :id=>canonical_uuid,
          :mapped_uuids => mapped_uuids.map {|mapping| mapping[:uuid]}
        )
      }
    end
  end

  class TagCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Tag.new(i).generate
      }
    end
  end
end
