# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LocalStore < Task::Tasklet
      helpers Task::LoggerHelper

      # download and prepare image file to ctx.os_devpath.
      def deploy_image(inst,ctx)
        raise NotImplementedError
      end

      def upload_image(inst, ctx, bo, ev_callback)
        raise NotImplementedError
      end

      def self.driver_class(hypervisor_name)
        case hypervisor_name.to_s
        when "dummy"
          Dcmgr::Drivers::DummyLocalStore
        when "kvm"
          Dcmgr::Drivers::LinuxLocalStore
        when "lxc"
          Dcmgr::Drivers::LinuxLocalStore
        when "esxi"
          Dcmgr::Drivers::ESXiLocalStore
        when "openvz"
          Dcmgr::Drivers::OpenvzLocalStore
        else
          raise "Unknown hypervisor type: #{hypervisor_name}"
        end
      end

    end
  end
end
