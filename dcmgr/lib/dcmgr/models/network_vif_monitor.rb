# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network service monitor entry for vifs.
  class NetworkVifMonitor < BaseNew
    taggable 'nwmon'

    many_to_one :network_vif

    subset(:alives, {:deleted_at => nil})

    plugin :serialization
    serialize_attributes :yaml, :params

    def self.monitor_class(key)
      CUSTOM_VALIDATOR[key].nil? ? nil : self
    end

    CUSTOM_VALIDATOR = {
      'icmp'  => lambda {
        self.params = {}
      },
      'udp'   => lambda {
        if self.params['port'].nil?
          errors.add(:port, "Not found port number")
        elsif params['port'] !~ /^\d+$/
          errors.add(:port, "Invalid port number: #{params['port']}")
        elsif !(0 .. 65534).include?(self.params['port'].to_i)
          errors.add(:port, "Out of UDP port range: #{self.port}")
        end
      },
      'tcp'   => lambda {
        if self.params['port'].nil?
          errors.add(:port, "Not found port number")
        elsif params['port'] !~ /^\d+$/
          errors.add(:port, "Invalid port number: #{params['port']}")
        elsif !(0 .. 65534).include?(self.params['port'].to_i)
          errors.add(:port, "Out of TCP port range: #{self.port}")
        end
      },
      'http'  => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
        
        if self.params['check_path'].nil?
          errors.add(:check_path, "Parameter not found")
        elsif self.params['check_path'] !~ %r{^/.*}
          errors.add(:check_path, "Invalid check path: #{self.params['check_path']}")
        end
      },
      'https' => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])

        if self.params['check_path'].nil?
          errors.add(:check_path, "Parameter not found")
        elsif self.params['check_path'] !~ %r{^/.*}
          errors.add(:check_path, "Invalid check path: #{self.params['check_path']}")
        end
      },
      'ftp'   => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      },
      'smtp'  => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      },
      'pop3'  => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      },
      'imap'  => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      },
      'dns'   => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['udp'])
        if self.params['query_record'].nil?
          errors.add(:query_record, "Parameter not found")
        elsif  self.params['query_record'] !~ %r{^[a-z0-9][a-z0-9\.\-]+}i
          errors.add(:query_record, "Invalid DNS name: #{self.params['query_record']}")
        end
      },
      'ssh'   => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      },
      'mysql' => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      },
      'pgsql' => lambda {
        self.instance_exec(&CUSTOM_VALIDATOR['tcp'])
      }
    }.freeze

    def to_hash
      hash = super
    end

    def validate
      super

      # if model.sti_model_map[self.protocol.to_s].nil?
      if CUSTOM_VALIDATOR[self.protocol.to_s].nil?
        errors.add(:protocol, "Unsupported protocol type: #{self.protocol}")
      end
      self.instance_exec(&CUSTOM_VALIDATOR[self.protocol.to_s])
    end

    private

    def before_validation
      # Set default title like "HTTP1", "HTTP2" if not assigned.
      if self.title.nil? || self.title == ""
        self.title = self.protocol.upcase + (self.class.alives.filter(:network_vif_id=>self.network_vif_id, :protocol=>self.protocol).count.to_i + 1).to_s
      end
      super
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

  end
end
