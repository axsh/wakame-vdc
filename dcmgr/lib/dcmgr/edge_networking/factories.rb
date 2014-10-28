# -*- coding: utf-8 -*-

module Dcmgr
  module VNet

    V = Dcmgr::VNet
    class TaskManagerFactory
      def self.create_task_manager(node)
        manager = V::Netfilter::VNicProtocolTaskManager.new
        manager.enable_ebtables = Dcmgr::Configurations.hva.enable_ebtables
        manager.enable_iptables = Dcmgr::Configurations.hva.enable_iptables
        manager.verbose_commands = Dcmgr::Configurations.hva.verbose_netfilter

        manager
      end
    end

  end
end
