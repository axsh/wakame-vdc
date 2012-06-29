# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancer < AccountResource
    taggable 'lb'
    one_to_one :instance, :class=>Instance, :key => :id
    one_to_many :load_balancer_targets, :key => :load_balancer_id do |ds|
      ds.filter(:is_deleted => 0) 
    end

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }

    def_dataset_method(:by_state) do |state|
      # SELECT * FROM `load_balancers` WHERE ('instance_id' IN (SELECT `id` FROM `instances` WHERE (`state` = 'running')))
      r = Instance.filter(:state => state).select(:id)
      filter(:instance_id => r)
    end

    def_dataset_method(:by_status) do |status|
      # SELECT * FROM `load_balancers` WHERE ('instance_id' IN (SELECT `id` FROM `instances` WHERE (`status` = 'online')))
      r = Instance.filter(:status => status).select(:id)
      filter(:instance_id => r)
    end
    
    class RequestError < RuntimeError; end

    def validate
      validates_includes ['http','https','tcp','ssl'], :protocol
      validates_includes ['http','https','tcp','ssl'], :instance_protocol
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
    
    def add_target(network_vif_id)
      lbt = LoadBalancerTarget.new
      lbt.network_vif_id = network_vif_id
      lbt.load_balancer_id = self.id
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

  end
end
