# -*- coding: utf-8 -*-

require "fuguta"

module Dcmgr
  module Configurations
    class Sta < Fuguta::Configuration

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
          c = Drivers::IscsiTarget.driver_class(driver_type)

          conf_class = Fuguta::Configuration::ConfigurationMethods.find_configuration_class(c)
          conf = conf_class.new(self.instance_variable_get(:@subject)).parse_dsl(&blk)
          @config[:iscsi_target_driver] = driver_type
          @config[:iscsi_target] = conf
        end
      end

      # obsolete parameters
      deprecated_warn_param :tmp_dir, :default=>'/var/tmp'
      deprecated_error_param :iscsi_target
      deprecated_warn_param :initiator_address,  :default=>'ALL'

      def validate(errors)
        if @config[:iscsi_target].nil?
          errors << "iscsi_target is unset."
        end

        if @config[:backing_store].nil?
          errors << "backing_store is unset."
        end
      end
    end
  end
end
