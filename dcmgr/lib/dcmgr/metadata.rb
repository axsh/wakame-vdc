# -*- coding: utf-8 -*-

module Dcmgr::Metadata
  I = Dcmgr::Constants::Image

  def self.factory(instance_hash, options = {})
    # We tell instances this is their first boot by placing a file named
    # first-boot on the metadata drive.
    # This is used by for example Windows instances. They need to generate
    # the administrator password on first boot.
    if options[:first_boot]
      AWSWithFirstBoot.new(instance_hash)
    else
      AWS.new(instance_hash)
    end
  end

  class MetadataType
    def initialize(instance_hash)
      @inst = instance_hash
    end

    def get_items
      raise NotImplementedError,
        "Classes inheriting from MetadataType must override the get_items method"
    end
  end
end
