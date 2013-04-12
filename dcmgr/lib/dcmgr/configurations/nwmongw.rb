# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Nwmongw < Configuration
      # Database connection string
      param :database_uri
      # AMQP broker to be connected.
      param :amqp_server_uri

      deprecated_warn_for :network, :network_id
      
      DSL do
        def driver(driver_name, &blk)
          @config[:driver_class] = klass = ::Dcmgr::Drivers::NetworkMonitoring.driver_class(driver_name)
          @config[:driver] = klass::Configuration.new(@subject).parse_dsl(&blk)
        end

        def network_id(nwuuid)
          @config[:networks] << nwuuid
        end
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

        unless self.driver
          errors << "driver is unset"
        end

        if self.networks.empty?
          errors << "None of Network UUID is set"
        end
      end
    end
  end
end
