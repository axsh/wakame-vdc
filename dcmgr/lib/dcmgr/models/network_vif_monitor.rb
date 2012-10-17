# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network service monitor entry for vifs.
  class NetworkVifMonitor < BaseNew
    taggable 'vifm'

    many_to_one :network_vif

    subset(:alives, {:deleted_at => nil})

    plugin :serialization
    serialize_attributes :yaml, :params

    def self.monitor_class(key)
      sti_model_map[key.to_s]
    end

    MONITOR_CLASSES = {
      'icmp'  => :ICMP,
      'udp'   => :UDP,
      'tcp'   => :TCP,
      'http'  => :HTTP,
      'https' => :HTTPS,
      'ftp'   => :FTP,
      'smtp'  => :SMTP,
      'pop3'  => :POP3,
      'imap'  => :IMAP,
      'dns'   => :SMTP,
      'ssh'   => :SSH,
      'mysql' => :MySQL,
      'pgsql' => :PostgreSQL
    }.freeze

    plugin :single_table_inheritance, :protocol, :model_map=>lambda {|v| self::Monitors.const_get(MONITOR_CLASSES[v], false) }, :key_map=>lambda{|klass|
      MONITOR_CLASSES.invert[klass.name.split('::').last.to_sym]
    }

    module Monitors
      class ICMP < NetworkVifMonitor
      end

      class TCP < NetworkVifMonitor
        def validate
          super

          if self.params['port'].nil?
            errors.add(:port, "Not found port number")
          elsif !(0 .. 65534).include?(self.params['port'].to_i)
            errors.add(:port, "Out of TCP port range: #{self.port}")
          end
        end

        def port
          raise "Undefined parameter: port" unless self.params.has_key?('port')
          self.params['port'].to_i
        end

        def port=(port)
          self.params['port'] = port.to_i
        end
      end

      class UDP < NetworkVifMonitor
        def validate
          super

          if self.params['port'].nil?
            errors.add(:port, "Not found port number")
          elsif !(0 .. 65534).include?(self.params['port'].to_i)
            errors.add(:port, "Out of TCP port range: #{self.port}")
          end
        end

        def port
          self.params['port'].to_i
        end

        def port=(port)
          self.params['port'] = port.to_i
        end
      end

      class HTTP < TCP
        def validate
          super

          if self.params['check_path'].nil?
            errors.add(:query_record, "Parameter not found")
          elsif self.params['check_path'] !~ %r{^/.*}
            errors.add(:check_path, "Invalid check path: #{self.params['check_path']}")
          end
        end

        def check_path
          self.params['check_path']
        end
      end

      class HTTPS < HTTP
      end

      class FTP < TCP
      end

      class SMTP < TCP
      end

      class IMAP < TCP
      end

      class POP3 < TCP
      end

      class DNS < UDP
        def validate
          super

          if self.params['query_record'].nil?
            errors.add(:query_record, "Parameter not found")
          elsif  self.params['query_record'] !~ %r{^[a-z0-9][a-z0-9\.\-]+}i
            errors.add(:query_record, "Invalid DNS name: #{self.params['query_record']}")
          end
        end
      end

      class SSH < TCP
      end

      class SMTP < TCP
      end

      class MySQL < TCP
      end

      class PostgreSQL < TCP
      end
    end

    def to_hash
      hash = super
    end

    def validate
      super

      if model.sti_model_map[self.protocol.to_s].nil?
        errors.add(:protocol, "Unsupported protocol type: #{self.protocol}")
      end
    end

    private

    def before_validation
      # Set default title like "HTTP1", "HTTP2" if not assigned.
      self.title ||= self.protocol.upcase + (self.class.alives.filter(:network_vif_id=>self.network_vif_id, :protocol=>self.protocol).count.to_i + 1).to_s
      send("#{model.sti_key}=", model.sti_key_map[model]) unless self[model.sti_key]
      super
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

  end
end
