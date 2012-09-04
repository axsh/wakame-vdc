# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancer < AccountResource
    taggable 'lb'
    many_to_one :instance
    one_to_many :load_balancer_targets, :key => :load_balancer_id do |ds|
      ds.filter(:is_deleted => 0) 
    end

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }

    def_dataset_method(:by_state) do |state|
      # SELECT * FROM `load_balancers` INNER JOIN `instances` ON
      # ((`load_balancers`.`instance_id` = `instances`.`id`) AND (`instances`.`state` = 'running'))
      self.join_table(:inner, :instances, {:load_balancers__instance_id=>:instances__id, :state=>state}).qualify_to_first_source
    end

    def_dataset_method(:by_status) do |status|
      # SELECT * FROM `load_balancers` INNER JOIN `instances` ON
      # ((`load_balancers`.`instance_id` = `instances`.`id`) AND (`instances`.`status` = 'online'))
      self.join_table(:inner, :instances, {:load_balancers__instance_id=>:instances__id, :status=>status}).qualify_to_first_source
    end
    
    class RequestError < RuntimeError; end

    def validate
      validates_includes ['http','https','tcp','ssl'], :protocol
      validates_includes ['http','tcp'], :instance_protocol
      validates_includes 1..65535, :port
      validates_includes 1..65535, :instance_port
    end

    def state
      @state = self.instance.state
    end

    def status
      @status = self.instance.status
    end
    
    def queue_name
      "loadbalancer.#{self.instance.canonical_uuid}"
    end
    
    def topic_name
      'amq.topic'
    end
    
    def queue_options
       { 
         :durable => false,
         :auto_delete => true,
         :internal => false,
         :no_declare => true
       }
    end

    def accept_port
      self.port
    end

    def connect_port
      if self.is_secure?
        self.port == 4433 ? 443 : 4433
      else
        self.port
      end
    end

    def is_secure?
      ['ssl', 'https'].include? self.protocol
    end

    def add_target(network_vif_id)
      lbt = LoadBalancerTarget.new
      lbt.network_vif_id = network_vif_id
      lbt.load_balancer_id = self.id
      lbt.fallback_mode = 'off'
      lbt.save
      lbt
    end

    def remove_target(network_vif_id)
      lbt = LoadBalancerTarget.find(:network_vif_id => network_vif_id, :is_deleted => 0)
      lbt.delete
      lbt
    end
 
    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

    def network_vifs(device_index=nil)
      if device_index
        self.instance.network_vif.select {|vif| vif if vif.device_index == device_index}[0]
      else
        self.instance.network_vif
      end
    end

    def target_network(network_vif_id)
      LoadBalancerTarget.where({:load_balancer_id => self.id, :network_vif_id => network_vif_id}).first
    end

  end
end
