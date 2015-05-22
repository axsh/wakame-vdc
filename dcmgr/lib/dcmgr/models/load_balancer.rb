# -*- coding: utf-8 -*-
require 'openssl'
require 'ipaddr'

module Dcmgr::Models
  class LoadBalancer < AccountResource
    include Dcmgr::Constants::LoadBalancer

    taggable 'lb'
    many_to_one :instance
    one_to_many :load_balancer_targets, :key => :load_balancer_id do |ds|
      ds.filter(:is_deleted => 0)
    end

    one_to_many :load_balancer_inbounds, :key => :load_balancer_id do |ds|
      ds.filter(:is_deleted => 0)
    end

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period|
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
      validates_includes SUPPORTED_INSTANCE_PROTOCOLS, :instance_protocol
      validates_includes 0..65535, :instance_port
      validates_private_key
      validates_public_key
      validates_allow_list
      validates_httpchk_path
    end

    def validates_private_key
      return true unless is_secure?

      if !check_encryption_algorithm
        errors.add(:private_key, "Doesn't support Algorithm")
      end

      if !check_private_key
        errors.add(:private_key, "Doesn't match")
      end

    end

    def validates_public_key
      return true unless is_secure?

      if !check_public_key
        errors.add(:public_key, "Invalid parameter")
      end
    end

    def validates_allow_list

      if allow_list.is_a?(String)
        ciders = allow_list.split(',')
      elsif allow_list.is_a?(Array)
        ciders = allow_list
      else
        errors.add(:allow_list, 'Invalid parameter')
        return false
      end

      if ciders.empty?
        errors.add(:allow_list, 'Empty CIDR')
        return false
      end

      ciders.each do |cider|
        begin
          ipaddr = IPAddr.new cider
          raise unless ipaddr.ipv4?
        rescue => e
          errors.add(:allow_list, "Invalid CIDR #{cider} or isn't ipv4")
          return false
        end
      end
      true
    end

    def validates_httpchk_path
      return true if httpchk_path.blank?

      begin
        URI.parse(httpchk_path)
      rescue URI::InvalidURIError => e
        errors.add(:httpchk_path, "Bad httpchk path: #{httpchk_path}")
        return false
      end
      true
    end

    def firewall_security_group
      self.global_vif.security_groups.find {|g| !g.rule.empty? }
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

    def is_secure?
      if !private_key.blank? && !public_key.blank?
        true
      else
        false
      end
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
      targets = LoadBalancerTarget.filter(:network_vif_id => network_vif_uuids, :is_deleted => 0, :load_balancer => self).all
      targets.each {|lbt|
        lbt.destroy
      }
      targets
    end

    def instance_security_group(instance_network_vif_uuid)
       LoadBalancerTarget.get_security_group(canonical_uuid, instance_network_vif_uuid)
    end

    def remove_instance_security_group(instance_network_vif_uuid)
      rl = ResourceLabel.filter(:name => label, :string_value => instance_network_vif_uuid).first
      raise "Unknown value #{instance_network_vif_uuid} in resource label #{label}" if rl.nil?

      security_group_id = rl.resource_uuid
      sg = SecurityGroup[security_group_id]
      sg.unset_label(label)
      global_vif.remove_security_group(sg)
      sg.destroy
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

    def add_inbound(protocol, port)
      lbi = LoadBalancerInbound.new
      lbi.load_balancer_id = self.id
      lbi.protocol = protocol
      lbi.port = port
      lbi.save
      lbi
    end

    def inbounds
      inbounds = []
      load_balancer_inbounds.each do |lbi|
        inbounds << {
          :protocol => lbi.protocol,
          :port => lbi.port
        }
      end
      inbounds
    end

    def remove_inbound
      load_balancer_inbounds.each {|ibi|
        ibi.destroy
      }
      load_balancer_inbounds
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

    def get_reload_config(values = {})
      config('reload:haproxy', values)
    end

    def ports
      inbounds.collect {|i| i[:port] }
    end

    def protocols
      inbounds.collect {|i| i[:protocol] }
    end

    def accept_secure_port
      inbounds.each {|_in|
        if SECURE_PROTOCOLS.include?(_in[:protocol])
          return _in[:port] == 4433 ? 443 : 4433
        end
      }
      nil
    end

    def secure_port
      inbounds.each {|_in|
        if SECURE_PROTOCOLS.include?(_in[:protocol])
          return _in[:port]
        end
      }
      nil
    end

    def secure_protocol
      inbounds.each {|_in|
        if SECURE_PROTOCOLS.include?(_in[:protocol])
          return _in[:protocol]
        end
      }
      nil
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

    def global_vif
      self.instance.network_vif_dataset.where(:device_index => PUBLIC_DEVICE_INDEX).first
    end

    def label
      ['load_balancer', uuid].join('.')
    end

    private

    def after_destroy
      super
      remove_inbound
    end

    def config(name, values = {})
      config_params = {}

      # setting command name
      config_params.merge!({
        :name => name
      })

      # engine params
      config_params.merge!({
        :ports => ports - [secure_port],
        :protocols => protocols,
        :secure_port => accept_secure_port,
        :secure_protocol => secure_protocol,
        :instance_protocol => instance_protocol,
        :instance_port => instance_port,
        :balance_algorithm => balance_algorithm,
        :cookie_name => cookie_name,
        :servers => get_target_servers,
        :httpchk_path => httpchk_path
      })

      # amqp message params
      config_params.merge!({
        :topic_name => topic_name,
        :queue_options => queue_options,
        :queue_name => queue_name,
      })

      config_params
    end

  end
end
