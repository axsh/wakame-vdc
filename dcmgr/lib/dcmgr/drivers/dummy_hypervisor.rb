# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class DummyHypervisor < Hypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      class Policy < HypervisorPolicy
        def on_associate_volume(instance, volume)
          volume.guest_device_name = volume.canonical_uuid
        end
      end

      def self.policy
        Policy.new
      end
      
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
            sh("tunctl -t %s" % [vif_uuid(vif)])
            sh("/sbin/ip link set %s up" % [vif_uuid(vif)])
            bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
            sh(attach_vif_to_bridge(bridge, vif))
          end
        }
      end

      def terminate_instance(hc)
        poweroff_instance(hc)
      end

      def poweroff_instance(hc)
        inst = hc.inst
        vifs = inst[:vif]

        vifs.each do |vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
            sh(detach_vif_from_bridge(bridge, vif))
            sh("/sbin/ip link set %s down" % [vif_uuid(vif)])
            sh("tunctl -d %s" % [vif_uuid(vif)])
          end
        end
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
