# -*- coding: utf-8 -*-
require 'fuguta'

module Dcmgr
  module Drivers
    class IscsiTarget
      attr_reader :node

      extend Fuguta::Configuration::ConfigurationMethods::ClassMethods

      def_configuration do
        param :iqn_prefix, :default=>'iqn.2010-09.jp.wakame'
      end

      # Retrive configuration section for this or child class.
      def self.driver_configuration
        Dcmgr.conf.iscsi_target
      end

      def driver_configuration
        Dcmgr.conf.iscsi_target
      end
      
      def create(ctx)
        raise NotImplmenetedError
      end

      def delete(ctx)
        raise NotImplmenetedError
      end

      # Register target information to the target device.
      # @param [Hash] volume hash data
      def register(volume)
        # TODO: uncomment here once all drivers were updated.
        #raise NotImplmenetedError
      end

      def self.driver_class(iscsi_target)
        case iscsi_target
        when 'tgt', "linux_iscsi"
          Dcmgr::Drivers::Tgt
        when "sun_iscsi"
          Dcmgr::Drivers::SunIscsi
        when "comstar"
          Dcmgr::Drivers::Comstar
        else
          raise "Unknown iscsi_target type: #{iscsi_target}"
        end
      end
    end
  end
end
