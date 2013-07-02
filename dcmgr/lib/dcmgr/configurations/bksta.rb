# -*- coding: utf-8 -*-

require 'uri'
require 'fuguta'

module Dcmgr
  module Configurations
    class Bksta < Fuguta::Configuration
      # AMQP broker to be connected.
      param :amqp_server_uri

      param :export_uri
      param :local_upload_uri

      param :site_over_rpc_timeout, :default=>10.0

      param :default_retry_max_per_job, :default=>2
      
      DSL do
        def driver(driver_name, &blk)
          @config[:driver_class] = klass = ::Dcmgr::Drivers::NetworkMonitoring.driver_class(driver_name)
          @config[:driver] = klass::Configuration.new(@subject).parse_dsl(&blk)
        end

        def destination(name, base_uri)
          raise "#{name} is registered already as destination name." if @config[:destinations].has_key?(name)
          @config[:destinations][name] = URI.parse(base_uri)
        end
      end

      def destinations
        @config[:destinations]
      end

      def after_initialize
        super
        @config[:destinations] = {}
      end

      def validate(errors)
        unless self.amqp_server_uri
          errors << "Unknown amqp_server_uri: #{self.amqp_server_uri}"
        end
        unless self.export_uri
          errors << "Unknown export_uri: #{self.export_uri}"
        else
          case self.export_uri
          when String
            @config[:export_uri] = URI.parse(@config[:export_uri]).freeze
          when URI
            self.export_uri.freeze
          else
            errors << "Unsupported type for export_uri: #{self.export_uri.class}"
          end
        end
        
        #unless self.driver
        #  errors << "driver is unset"
        #end
      end
    end
  end
end
