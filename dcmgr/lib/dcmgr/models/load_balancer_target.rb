# -*- coding: utf-8 -*-
module Dcmgr::Models
  class LoadBalancerTarget < AccountResource
    class RequestError < RuntimeError; end

    many_to_one :load_balancer
    subset(:alives, {:deleted_at => nil})

    def validate
      validates_includes ['on', 'off'], :fallback_mode
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.is_deleted = self.id
      self.save_changes
    end

    def self.get_targets(network_vif_id)
      self.filter(:network_vif_id => network_vif_id).alives.group_by(:load_balancer_id).all
    end

    def self.get_security_group(load_balancer_id, network_vif_id)
      unless get_targets(network_vif_id).empty?
        security_groups = NetworkVif[network_vif_id].security_groups_dataset.where(:service_type => LoadBalancer::SERVICE_TYPE)
        sg_uuids = security_groups.collect{|sg| sg.canonical_uuid }

        sg = []
        sg_uuids.each {|uuid|
          sg = SecurityGroup[uuid]
          break if sg.label(LoadBalancer[load_balancer_id].label)
        }
        sg
      end
    end

    def self.get_load_balancers(network_vif_id)
      load_balancers = []
      targets = self.get_targets(network_vif_id)
      targets.each  { |t|
        load_balancers << t.load_balancer
      }
      load_balancers
    end
  end
end
