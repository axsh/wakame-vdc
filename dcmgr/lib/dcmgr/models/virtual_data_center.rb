# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenter < AccountResource
    taggable 'vdc'

    one_to_one :virtual_data_center_spec
    alias :vdc_spec :virtual_data_center_spec 

    one_to_many :virtual_data_center_instance
    alias :vdc_instances :virtual_data_center_instance

    many_to_many :instances, :class=>Instance, :join_table=>:virtual_data_center_instances, :right_key=>:instance_id, :right_primary_key=>:id do |ds|
      # "SELECT `instances`.* FROM `instances` INNER JOIN `virtual_data_center_instances` ON 
      # ((`virtual_data_center_instances`.`instance_id` = `instances`.`id`) AND (`virtual_data_center_instances`.`virtual_data_center_id` = 56))
      # WHERE (terminated_at IS NULL OR terminated_at >= '2015-07-29 05:59:15')"
      ds.alives_and_termed
    end

    def self.entry_new(account)
      vdc = self.new
      vdc.account_id = account.canonical_uuid
      vdc.save
      vdc
    end

    def add_virtual_data_center_spec(type, spec, spec_file)
      # Mash is passed in some cases.
      raise ArgumentError, "The spec_file parameter must be a Hash. Got '#{spec_file.class}'" if !spec_file.is_a?(Hash)
      vdcs = VirtualDataCenterSpec.new
      vdcs.virtual_data_center_id = self.id
      vdcs.type = type
      vdcs.spec = spec
      vdcs.spec_file = spec_file
      vdcs.save
      vdcs
    end

    def add_virtual_data_center_instance(instance_ids)
      # Mash is passed in some cases.
      raise ArgumentError, "The instance_ids parameter must be a Array. Got '#{instance_ids.class}'" if !instance_ids.is_a?(Array)
      instance_ids.each { |instance_id|
        vdci = VirtualDataCenterInstance.new
        vdci.virtual_data_center_id = self.id
        vdci.instance_id = instance_id
        vdci.save
      }
    end

    def before_destroy
      self.vdc_spec.destroy
      self.virtual_data_center_instance.each do |vdc_instance|
        vdc_instance.destroy
      end
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end
  end
end
