# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking

    EN = Dcmgr::EdgeNetworking
    class TaskManagerFactory
      def self.create_task_manager(node)
        manager = EN::Netfilter::VNicProtocolTaskManager.new
        manager.enable_ebtables = Dcmgr.conf.enable_ebtables
        manager.enable_iptables = Dcmgr.conf.enable_iptables
        manager.verbose_commands = Dcmgr.conf.verbose_netfilter

        manager
      end
    end

  end
end
