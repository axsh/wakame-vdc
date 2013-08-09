# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Volume < Dcmgr::Endpoints::ResponseGenerator
    def initialize(volume)
      raise ArgumentError if !volume.is_a?(Dcmgr::Models::Volume)
      @volume = volume
    end

    def generate()
      @volume.instance_exec {
        to_hash.merge(:id=>canonical_uuid,
                      :instance_id=>(self.instance.nil? ? nil : self.instance.canonical_uuid),
                      :labels=>resource_labels.map{ |l| ResourceLabel.new(l).generate })
      }
    end
  end

  class VolumeCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Volume.new(i).generate
      }
    end
  end
end
