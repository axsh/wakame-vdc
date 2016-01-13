# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class VirtualDataCenter < Dcmgr::Endpoints::ResponseGenerator
    def initialize(virtual_data_center)
      raise ArgumentError if !virtual_data_center.is_a?(Dcmgr::Models::VirtualDataCenter)
      @virtual_data_center = virtual_data_center
    end

    def generate()
      @virtual_data_center.instance_exec {
        h = {
          :uuid => canonical_uuid,
          :account_id => account_id,
          :capacity => self.spec.instance_capacity,
          :vdc_spec => self.spec.file,
          :instances => [],
          :created_at => created_at,
          :updated_at => updated_at,
          :deleted_at => deleted_at,
        }

        self.instances.each do |i|
          instance = {
            :uuid => i.canonical_uuid,
            :state => i.state,
          }
          h[:instances] << instance

          user_data = YAML.load(i.user_data)
          next if user_data.nil?

          port = user_data['port']

          i.instance_nic.each do |vif|
            direct_lease = vif.direct_ip_lease_dataset.first
            unless direct_lease.nil?
              h[:endpoint] = "#{direct_lease.ipv4}:#{user_data['port']}"
            end
          end
        end

        sg_hash = {}
        self.security_groups.each { |sg|
          sg_hash[sg.name_in_virtual_data_center_spec] = {
            uuid: sg.canonical_uuid,
            rules: sg.rule
          }
        }
        h[:security_groups] = sg_hash

        h
      }
    end
  end

  class VirtualDataCenterCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |vdc|
        VirtualDataCenter.new(vdc).generate
      }
    end
  end
end
