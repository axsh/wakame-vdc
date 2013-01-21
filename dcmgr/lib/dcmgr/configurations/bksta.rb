# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Bksta < Configuration
      # AMQP broker to be connected.
      param :amqp_server_uri

      DSL do
        def driver(driver_name, &blk)
          @config[:driver_class] = klass = ::Dcmgr::Drivers::NetworkMonitoring.driver_class(driver_name)
          @config[:driver] = klass::Configuration.new(@subject).parse_dsl(&blk)
        end
      end

      def after_initialize
        super
      end

      def validate(errors)
        unless self.amqp_server_uri
          errors << "Unknown amqp_server_uri: #{self.amqp_server_uri}"
        end

        #unless self.driver
        #  errors << "driver is unset"
        #end
      end
    end
  end
end
