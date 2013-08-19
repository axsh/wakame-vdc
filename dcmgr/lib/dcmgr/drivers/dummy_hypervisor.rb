# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class DummyHypervisor < Hypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      def self.local_store_class
        DummyLocalStore
      end

      def initialize
      end

      def run_instance(hc)
        poweron_instance(hc)
      end

      def poweron_instance(hc)
        inst = hc.inst
        vifs = inst[:vif]

        vifs.each { |vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            sh("tunctl -t %s" % [vif[:uuid]])
            sh("/sbin/ip link set %s up" % [vif[:uuid]])
            sh("#{Dcmgr.conf.brctl_path} addif %s %s" % [bridge_if_name(vif[:ipv4][:network][:dc_network]), vif[:uuid]])
          end
        }
      end

      def terminate_instance(hc)
        poweroff_instance(hc)
      end

      def poweroff_instance(hc)
        inst = hc.inst
        vifs = inst[:vif]

        vifs.each { |vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            sh("#{Dcmgr.conf.brctl_path} delif %s %s" % [bridge_if_name(vif[:ipv4][:network][:dc_network]), vif[:uuid]])
            sh("/sbin/ip link set %s down" % [vif[:uuid]])
            sh("tunctl -d %s" % [vif[:uuid]])
          end
        }
      end

      def reboot_instance(hc)
      end

      def attach_volume_to_guest(hc)
      end

      def detach_volume_from_guest(hc)
      end

      def check_instance(i)
      end

      Task::Tasklet.register(self) {
        self.new
      }
    end
  end
end
