# -*- coding: utf-8 -*-

require "fuguta"
require "dcmgr/drivers/network_monitoring"

module Dcmgr
  module Configurations
    class Nwmongw < Fuguta::Configuration
      # Database connection string
      param :database_uri
      # AMQP broker to be connected.
      param :amqp_server_uri

      deprecated_warn_for :network, :network_id

      usual_paths [
        ENV['CONF_PATH'].to_s,
        '/etc/wakame-vdc/nwmongw.conf',
        File.expand_path('config/nwmongw.conf', ::Dcmgr::DCMGR_ROOT)
      ]

      DSL do
        def driver(driver_name, &blk)
          @config[:driver_class] = klass = ::Dcmgr::Drivers::NetworkMonitoring.driver_class(driver_name)
          if blk
            @config[:driver_conf] = klass::Configuration.new(@subject).parse_dsl(&blk)
          end
        end

        def network_id(nwuuid)
          @config[:networks] << nwuuid
        end
      end

      # Backward compatibility.
      def driver
        @config[:driver_conf]
      end

      def after_initialize
        super

        @config[:networks] = []
      end

      def validate(errors)
        unless self.database_uri
          errors << "Unknown database_uri: #{self.database_uri}"
        end
        unless self.amqp_server_uri
          errors << "Unknown amqp_server_uri: #{self.amqp_server_uri}"
        end

        unless self.driver_class
          errors << "driver is unset"
        end

        if self.driver_conf
          if !self.driver_conf.is_a?(::Dcmgr::Drivers::NetworkMonitoring::Configuration)
            errors << "Unsupported driver_conf class type: #{self.driver_conf.class}"
          end
        end

        if self.networks.empty?
          errors << "None of Network UUID is set"
        end
      end
    end
  end
end
