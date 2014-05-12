# -*- coding: utf-8 -*-
require 'fuguta'

module Dcmgr
  module Drivers
    class StorageTarget
      extend Fuguta::Configuration::ConfigurationMethods::ClassMethods

      def_configuration

      # Retrive configuration section for this or child class.
      def self.driver_configuration
        Dcmgr.conf.sotrage_target
      end

      def driver_configuration
        Dcmgr.conf.storage_target
      end

      def create(ctx)
        raise NotImplmenetedError
      end

      def delete(ctx)
        raise NotImplmenetedError
      end

      def self.driver_class(target_name)
        case target_name
        when 'nfs'
          Dcmgr::Drivers::Nfs
        when 'tgt', "linux_iscsi"
          Dcmgr::Drivers::Tgt
        when "sun_iscsi"
          Dcmgr::Drivers::SunIscsi
        when "comstar"
          Dcmgr::Drivers::Comstar
        when "indelible_iscsi"
          Dcmgr::Drivers::IndelibleIscsi
        else
          raise "Unknown storage target type: #{target_name}"
        end
      end
    end
  end
end
