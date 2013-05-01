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
            :vif_index => vif.device_index,
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

        network_vif_ids = load_balancer_targets.collect {|t|
          t[:network_vif_id].split('-')[1]
        }

        network_vifs = {}
        Dcmgr::Models::NetworkVif.where(:uuid => network_vif_ids).all.each {|t|
          network_vifs[t.canonical_uuid] = {
           :instance_id => t.instance.canonical_uuid,
           :display_name => t.instance.display_name,
          }
        }

        target_vifs = load_balancer_targets.collect {|t|
          {
            :network_vif_id => t.network_vif_id,
            :instance_id => network_vifs[t.network_vif_id][:instance_id],
            :display_name => network_vifs[t.network_vif_id][:display_name],
            :fallback_mode => t[:fallback_mode]
          }
        }

        allow_list = self[:allow_list].split(',') unless self[:allow_list].blank?
        th = to_hash.merge(:id=>canonical_uuid,
              :state=>state,
              :status=>status,
              :target_vifs=> target_vifs,
              :vif=>h[:vif],
              :instance_id=>instance.canonical_uuid,
              :allow_list=>allow_list,
              :inbounds => load_balancer_inbounds_dataset.alives.all.map {|m|
                LoadBalancerInbound.new(m).generate
              },
              :httpchk=>{:path => self[:httpchk_path]}
        )
        th.delete(:httpchk_path)
        th
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

  class LoadBalancerInbound < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::LoadBalancerInbound)
      @object = object
    end

    def generate()
      @object.instance_exec {
        { :port => self.port,
          :protocol => self.protocol,
        }
      }
    end
  end

end
