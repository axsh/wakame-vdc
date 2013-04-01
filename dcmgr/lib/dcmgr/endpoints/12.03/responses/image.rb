# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Image < Dcmgr::Endpoints::ResponseGenerator
    def initialize(image)
      raise ArgumentError if !image.is_a?(Dcmgr::Models::Image)
      @image = image
    end

    def generate()
      @image.instance_exec {
        to_hash.merge(:id=>canonical_uuid, :labels=>resource_labels.map{ |l| ResourceLabel.new(l).generate })
      }
    end
  end

  class ImageCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Image.new(i).generate
      }
    end
  end
end
