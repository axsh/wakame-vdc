# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancer < AccountResource
    taggable 'lb'
    one_to_one :instance, :class=>Instance, :key => :id
    one_to_many :load_balancer_targets, :key => :load_balancer_id do |ds|
      ds.filter(:is_deleted => 0) 
    end

    class RequestError < RuntimeError; end
    
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
    
    def add_target(network_vif_uuid)
      lbt = LoadBalancerTarget.new
      lbt.network_vif_id = network_vif_uuid
      lbt.load_balancer_id = self.id
      lbt.save
      lbt
    end

    def remove_target(network_vif_id)
      lbt = LoadBalancerTarget.find(:network_vif_id => network_vif_id)
      lbt.delete
    end
 
    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.is_deleted = self.id
      self.save_changes
    end      

  end
end
