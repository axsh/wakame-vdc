# -*- coding: utf-8 -*-

module Dcmgr::Metadata
  I = Dcmgr::Constants::Image

  # Factory method
  def self.md_type(instance_hash)
    os_type  = instance_hash[:image][:os_type]
    password = instance_hash[:encrypted_password]

    # Windows instances that don't have a password generated yet
    # need to be told to generate one.
    if os_type == I::OS_TYPE_WINDOWS && password.nil?
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
