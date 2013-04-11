# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network_vif'
require 'multi_json'

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
          :service_type => self.service_type,
          :monitoring => {
            :enabled => self.instance_monitor_attr.enabled,
            :mail_address => self.instance_monitor_attr.recipients.select{|i| i.has_key?(:mail_address) }.map{|i| i[:mail_address] },
            :process => [],
          },
          :labels=>resource_labels.map{ |l| ResourceLabel.new(l).generate },
        }

        tmp = {}
        self.resource_labels_dataset.grep(:name, 'monitoring.process.%').each { |l|
          dummy, dummy, idx, key = l.name.split('.', 4)
          tmp[idx] ||= {:enabled=>false, :uuid=>nil, :params=>{}}
          case key
          when 'params'
            tmp[idx][:params]=MultiJson.load(l.value)
          when 'enabled'
            tmp[idx][:enabled] = (l.value == 'true')
          else
            tmp[idx][key.to_sym]= l.value
          end
        }
        
        h[:monitoring][:process] = tmp.values

        if self.ssh_key_pair
          h[:ssh_key_pair] = {
            :uuid => self.ssh_key_pair.canonical_uuid,
            :display_name => self.ssh_key_pair.display_name,
          }
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
