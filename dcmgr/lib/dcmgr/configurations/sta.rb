# -*- coding: utf-8 -*-

require "dcmgr/configurations/features"
require "fuguta"

module Dcmgr
  module Configurations
    class Sta < Features

      usual_paths [
        ENV['CONF_PATH'].to_s,
        '/etc/wakame-vdc/sta.conf',
        File.expand_path('config/sta.conf', ::Dcmgr::DCMGR_ROOT)
      ]

      DSL do
        # backing_store_driver configuration section.
        def backing_store_driver(driver_type, &blk)
          c = Drivers::BackingStore.driver_class(driver_type)

          conf_class = Fuguta::Configuration::ConfigurationMethods.find_configuration_class(c)
          conf = conf_class.new(self.instance_variable_get(:@subject)).parse_dsl(&blk)
          @config[:backing_store_driver] = driver_type
          @config[:backing_store] = conf
          @config["#{driver_type}_backing_store"] = conf
        end

        # target_driver configuration section.
        def target_driver(driver_type, &blk)
          c = Drivers::StorageTarget.driver_class(driver_type)

          conf = Fuguta::Configuration::ConfigurationMethods.find_configuration_class(c).new(self.instance_variable_get(:@subject)).parse_dsl(&blk)
          @config[:storage_target_driver] = driver_type
          @config[:storage_target] = conf
        end
      end

      def iscsi_target_driver
        @config[:storage_target_driver]
      end
      def iscsi_target
        @config[:storage_target]
      end

      # obsolete parameters
      deprecated_warn_param :tmp_dir, :default=>'/var/tmp'
      deprecated_error_param :iscsi_target
      deprecated_warn_param :initiator_address,  :default=>'ALL'

      def validate(errors)
        if @config[:storage_target].nil?
          errors << "storage_target is unset."
        end

        if @config[:backing_store].nil?
          errors << "backing_store is unset."
        end
      end
    end
  end
end
