module Dcmgr
  module Drivers
    class Hypervisor

      def run_instance(hc)
      end

      def terminate_instance(hc)
      end

      def reboot_instance(hc)
      end

      def attach_volume_to_guest(hc)
      end

      def detach_volume_from_guest(hc)
      end

      def self.select_hypervisor(hypervisor)
        case hypervisor
        when "kvm"
          hv = Dcmgr::Drivers::Kvm.new
        when "lxc"
          hv = Dcmgr::Drivers::Lxc.new
        when "esxi"
          hv = Dcmgr::Drivers::ESXi.new
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
        hv
      end
    end
  end
end
