# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Nwmongw < Configuration
      # Database connection string
      param :database_uri
      # AMQP broker to be connected.
      param :amqp_server_uri

      def validate(errors)
        unless self.database_uri
          errors << "Unknown database_uri: #{self.database_uri}"
        end
        unless self.amqp_server_uri
          errors << "Unknown amqp_server_uri: #{self.amqp_server_uri}"
        end
      end
    end
  end
end
