# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Instance < Dcmgr::Endpoints::ResponseGenerator
    def initialize(instance)
      raise ArgumentError if !instance.is_a?(Dcmgr::Models::Instance)
      @instance = instance
    end

    def generate()
      @instance.instance_exec {
        h = {
          :id => canonical_uuid,
          :account_id => account_id,
          :host_node   => self.host_node && self.host_node.canonical_uuid,
          :cpu_cores   => cpu_cores,
          :memory_size => memory_size,
          :arch        => image.arch,
          :image_id    => image.canonical_uuid,
          :created_at  => self.created_at,
          :state => self.state,
          :status => self.status,
          :ssh_key_pair => nil,
          :volume => [],
          :vif => [],
          :hostname => hostname,
          :ha_enabled => ha_enabled,
          :hypervisor => hypervisor,
          :display_name => self.display_name,
          :service_type => self.service_type
        }
        if self.ssh_key_data
          h[:ssh_key_pair] = self.ssh_key_data[:uuid]
        end

        instance_nic.each { |vif|
          direct_lease_ds = vif.direct_ip_lease_dataset

          network = vif.network
          ent = {
            :vif_id => vif.canonical_uuid,
            :network_id => network.nil? ? nil : network.canonical_uuid,
          }

          direct_lease = direct_lease_ds.first
          if direct_lease.nil?
          else
            outside_lease = direct_lease.nat_outside_lease
            ent[:ipv4] = {
              :address=> direct_lease.ipv4,
              :nat_address => outside_lease.nil? ? nil : outside_lease.ipv4,
            }
          end
          
          ent[:security_groups] = vif.security_groups.map {|sg| sg.canonical_uuid}
          
          h[:vif] << ent
        }

        self.volume.each { |v|
          h[:volume] << {
            :vol_id => v.canonical_uuid,
            :guest_device_name=>v.guest_device_name,
            :state=>v.state,
          }
        }

        h
      }
    end
  end

  class InstanceCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Instance.new(i).generate
      }
    end
  end
end
