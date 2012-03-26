# -*- coding: utf-8 -*-

require 'rbvmomi'

module Dcmgr
  module Drivers
    class ESXi < Hypervisor
      include RbVmomi
      def run_instance(ctx)
        vm = find_vm(ctx)
        
        vm.PowerOnVM_Task.wait_for_completion
      end

      def terminate_instance(ctx)
        vm = find_vm(ctx)
        
        vm.PowerOffVM_Task.wait_for_completion
        vm.Destroy_Task.wait_for_completion
        
        ## Delete the metadata iso
        opts = esxi_options(ctx)
        vim = RbVmomi::VIM.connect opts
        dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or raise "datacenter [#{opts[:datacenter]}] not found"
        
        ds = dc.find_datastore(opts[:datastore])
        fm = ds._connection.serviceContent.fileManager

        dsPath = "[#{ds.name}] #{ctx.inst[:uuid]}"

        fm.DeleteDatastoreFile_Task(:name => dsPath, :datacenter => dc).wait_for_completion
      end

      def reboot_instance(hc)
        vm = find_vm(ctx)
        vm.PowerOffVM_Task.wait_for_completion
        vm.PowerOnVM_Task.wait_for_completion
      end

      def attach_volume_to_guest(hc)
        raise NotImplementedError
      end

      def detach_volume_from_guest(hc)
        raise NotImplementedError
      end
      
      #def setup_metadata_iso(ctx)
        
      #end
      
      private
      def find_vm(ctx)
        inst = ctx.inst
        
        vmname = inst[:uuid]
        
        opts = esxi_options(ctx)
        
        vim = RbVmomi::VIM.connect opts
        dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or raise "datacenter [#{opts[:datacenter]}] not found"

        vm = dc.find_vm(vmname) or raise "VM [#{vmname}] not found"
      end
      
      def esxi_options(ctx)
        {
          :host => ctx.node.manifest.config.esxi_ipaddress,
          :user => ctx.node.manifest.config.esxi_username,
          :password => ctx.node.manifest.config.esxi_password,
          :insecure => true,
          :datastore => ctx.node.manifest.config.esxi_datastore,
          :datacenter => ctx.node.manifest.config.esxi_datacenter,
        }
      end
      #def upload_image(image_host,image_name,esxi_server_ip,esxi_user,esxi_password,esxi_datastore_name)
        #sh("curl -s -o - #{image_host}/#{image_name} | curl -s -u #{esxi_user}:#{esxi_password} -k -T - https://#{esxi_server_ip}/folder/dnsmasq.deb?dsName=datastore1")
      #end
    end
  end
end
