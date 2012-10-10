# -*- coding: utf-8 -*-
require 'openssl'

module Dcmgr::Models
  class LoadBalancer < AccountResource

    PROTOCOLS = ['http', 'tcp'].freeze
    SECURE_PROTOCOLS = ['https', 'ssl'].freeze
    SUPPORTED_PROTOCOLS = (PROTOCOLS + SECURE_PROTOCOLS).freeze
    SUPPORTED_INSTANCE_PROTOCOLS = PROTOCOLS

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
      validates_includes SUPPORTED_PROTOCOLS, :protocol
      validates_includes SUPPORTED_INSTANCE_PROTOCOLS, :instance_protocol
      validates_includes 1..65535, :port
      validates_includes 1..65535, :instance_port
      validates_private_key
      validates_public_key
    end

    def validates_private_key
      return true if PROTOCOLS.include? protocol

      if !check_encryption_algorithm
        errors.add(:private_key, "Doesn't support Algorithm")
      end

      if !check_private_key
        errors.add(:private_key, "Doesn't match")
      end

    end

    def validates_public_key
      return true if PROTOCOLS.include? protocol

      if !check_public_key
        errors.add(:public_key, "Invalid parameter")
      end
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
      SECURE_PROTOCOLS.include? self.protocol
    end

    def add_target(network_vif_id)
      lbt = LoadBalancerTarget.new
      lbt.network_vif_id = network_vif_id
      lbt.load_balancer_id = self.id
      lbt.fallback_mode = 'off'
      lbt.save
      lbt
    end

    def remove_targets(network_vif_uuids)
      targets = LoadBalancerTarget.filter(:network_vif_id => network_vif_uuids, :is_deleted => 0).all
      targets.each {|lbt|
        lbt.destroy
      }
      targets
    end

    def get_target_servers(options = {})
      exclude_vifs = []
      if !options.empty? && options.has_key?(:exclude_vifs)
         exclude_vifs = options[:exclude_vifs]
      end

      servers = []
      self.load_balancer_targets_dataset.exclude(:network_vif_id => exclude_vifs).all.each {|lbt|
        network_vif = NetworkVif[lbt.network_vif_id]
        servers << {
          :ipv4 => network_vif.ip.first.ipv4,
          :backup => lbt.fallback_mode
        }
      }
      servers
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

    def check_public_key
      begin
        c = OpenSSL::X509::Certificate.new(public_key)
        c.is_a? OpenSSL::X509::Certificate
      rescue => e
        false
      end
    end

    def check_private_key
      begin
        c = OpenSSL::X509::Certificate.new(public_key)
        c.check_private_key(@checked_private_key)
      rescue => e
        false
      end
    end

    def check_encryption_algorithm
      [
       OpenSSL::PKey::RSA,
       OpenSSL::PKey::DSA
      ].find do |algo|
        return false unless defined? algo
        begin
          @checked_private_key = algo.new(private_key) {
            # If you have a passphrase, It evaluate a false.
          }
          return true if @checked_private_key
        rescue => e
          false
        end
      end
    end

  end
end
