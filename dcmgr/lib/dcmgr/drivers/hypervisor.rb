# -*- coding: utf-8 -*-

require "fuguta"

module Dcmgr
  module Drivers
    class Hypervisor < Task::Tasklet
      extend Fuguta::Configuration::ConfigurationMethods::ClassMethods

      def_configuration

      # Retrive configuration section for this or child class.
      def self.driver_configuration
        Dcmgr.conf.hypervisor_driver(self)
      end

      def driver_configuration
        Dcmgr.conf.hypervisor_driver(self.class)
      end

      def run_instance(hc)
      end

      def terminate_instance(hc)
      end

      def reboot_instance(hc)
      end

      def poweroff_instance(hc)
      end

      def poweron_instance(hc)
      end

      def check_interface(hc)
      end

      def setup_metadata_drive(hc,metadata_items)
      end

      def attach_volume_to_guest(hc)
      end

      def detach_volume_from_guest(hc)
      end

      def attach_volume_to_host(hc, volume_id)
      end

      def detach_volume_from_host(hc)
      end
      
      def check_instance(uuid)
      end

      def soft_poweroff_instance(hc)
        poweroff_instance(hc)
      end

      @@policy = HypervisorPolicy.new
      def self.policy
        @@policy
      end

      def self.local_store_class
        raise NotImplementedError
      end

      # deprecated
      def self.select_hypervisor(hypervisor)
        driver_class(hypervisor).new
      end

      def self.driver_class(hypervisor)
        case hypervisor.to_s
        when "dummy"
          Dcmgr::Drivers::DummyHypervisor
        when "kvm"
          Dcmgr::Drivers::Kvm
        when "lxc"
          Dcmgr::Drivers::Lxc
        when "esxi"
          Dcmgr::Drivers::ESXi
        when "openvz"
          Dcmgr::Drivers::Openvz
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
      end

    end
  end
end
