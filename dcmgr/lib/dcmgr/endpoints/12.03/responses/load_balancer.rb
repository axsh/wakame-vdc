# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class LoadBalancer < Dcmgr::Endpoints::ResponseGenerator
    def initialize(load_balancer)
      raise ArgumentError if !load_balancer.is_a?(Dcmgr::Models::LoadBalancer)
      @load_balancer = load_balancer
    end

    def generate()
      @load_balancer.instance_exec {
        h = {
          :vif => []
        }

        # TODO: move to helper method with using instance.
        instance.instance_nic.each {|vif|
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
          h[:vif] << ent
        }

        network_vif_ids = []
        load_balancer_targets.collect {|t|
          network_vif_ids << t[:network_vif_id].split('-')[1]
        }

        target_instances = Dcmgr::Models::NetworkVif.where(:uuid => network_vif_ids).all.collect{|t|t.instance.canonical_uuid}
        to_hash.merge(:id=>canonical_uuid,
              :state=>state,
              :status=>status,
              :target_instances=> target_instances,
              :vif=>h[:vif]
        )
      }
    end
  end

  class LoadBalancerCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        LoadBalancer.new(i).generate
      }
    end
  end
end
