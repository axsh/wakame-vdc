# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module Image
    STATE_CREATING = "creating".freeze
    STATE_PENDING = "pending".freeze
    STATE_AVAILABLE = "available".freeze
    
    STATES=[STATE_CREATING, STATE_PENDING, STATE_AVAILABLE].freeze

    FEATURE_VIRTIO='virtio'.freeze
    FEATURE_ACPI='acpi'.freeze
    FEATURES=[FEATURE_VIRTIO, FEATURE_ACPI].freeze

    BOOT_DEV_SAN=1
    BOOT_DEV_LOCAL=2

    BOOT_DEV_FLAGS = [BOOT_DEV_SAN, BOOT_DEV_LOCAL].freeze

    CLONED_FIELDS_AT_TRANSFER=[:account_id,
                               :display_name,
                               :service_type,
                               :description,
                               :boot_dev_type,
                               :arch,
                               :features,
                               :file_format,
                               :root_device,
                               :instance_model_name,
                               :parent_image_id,
                               :backup_object_id
                              ].freeze
  end
end
