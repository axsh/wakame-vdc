# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LocalStore

      # download and prepare image file to ctx.os_devpath.
      def deploy_image(inst,ctx)
        raise NotImplementedError
      end

      def upload_image(inst, ctx, bo, ev_callback)
        raise NotImplementedError
      end
      
      def self.select_local_store(hypervisor)
        case hypervisor
        when "kvm"
          ls = Dcmgr::Drivers::LinuxLocalStore.new
        when "lxc"
          ls = Dcmgr::Drivers::LinuxLocalStore.new
        when "esxi"
          ls = Dcmgr::Drivers::ESXiLocalStore.new
        when "openvz"
          ls = Dcmgr::Drivers::OpenvzLocalStore.new
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
        ls
      end
      
    end
  end
end
