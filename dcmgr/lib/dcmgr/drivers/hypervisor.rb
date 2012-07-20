# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Hypervisor

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

      def check_instance(uuid)
      end

      def self.select_hypervisor(hypervisor)
        case hypervisor
        when "kvm"
          hv = Dcmgr::Drivers::Kvm.new
        when "lxc"
          hv = Dcmgr::Drivers::Lxc.new
        when "esxi"
          hv = Dcmgr::Drivers::ESXi.new
        when "openvz"
          hv = Dcmgr::Drivers::Openvz.new
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
        hv
      end
    end
  end
end
