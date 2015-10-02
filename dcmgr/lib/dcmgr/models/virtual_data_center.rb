# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenter < AccountResource
    taggable 'vdc'

    many_to_one :virtual_data_center_spec
    alias :spec :virtual_data_center_spec

    one_to_many :instances

    subset(:alives, {:deleted_at => nil})

    def self.entry_new(account, &blk)
      raise ArgumentError, "The account parameter must be an Account. Got '#{account.class}'" unless account.is_a?(Account)

      vdc = self.new &blk
      vdc.account_id = account.canonical_uuid
      vdc.save
      vdc
    end

    def add_virtual_data_center_instance(instances)
      # Mash is passed in some cases.
      raise ArgumentError, "The instance_ids parameter must be a Array. Got '#{instances.class}'" if !instances.is_a?(Array)
      instances.each { |instance|
        instance.virtual_data_center_id = self.id
        instance.save_changes
      }
    end

    def before_destroy
      self.instances.each do |instance|
        instance.destroy
      end
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end
  end
end
