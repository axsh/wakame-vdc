# -*- coding: utf-8 -*-

require 'rbvmomi'

module Dcmgr
  module Drivers
    class ESXi < Hypervisor
      include RbVmomi
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def self.local_store_class
        EsxiLocalStore
      end

      def_configuration

      def run_instance(ctx)
        vm = find_vm(ctx)

        vm.PowerOnVM_Task.wait_for_completion
      end

      def terminate_instance(ctx)
        vm = find_vm(ctx)

        vm.PowerOffVM_Task.wait_for_completion
        vm.Destroy_Task.wait_for_completion

        ## Delete the metadata iso
        opts = self.class.settings(ctx)
        vim = RbVmomi::VIM.connect opts
        dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or raise "datacenter [#{opts[:datacenter]}] not found"

        ds = dc.find_datastore(opts[:datastore])
        fm = ds._connection.serviceContent.fileManager

        dsPath = "[#{ds.name}] #{ctx.inst[:uuid]}"

        fm.DeleteDatastoreFile_Task(:name => dsPath, :datacenter => dc).wait_for_completion
      end

      def reboot_instance(ctx)
        vm = find_vm(ctx)
        vm.PowerOffVM_Task.wait_for_completion
        vm.PowerOnVM_Task.wait_for_completion
      end

      def setup_metadata_drive(ctx,metadata_items)
        super(ctx,metadata_items)

        opts = self.class.settings(ctx)

        begin
          sh("genisoimage -V META_CD -R -o #{ctx.inst_data_dir}/metadata.iso #{ctx.metadata_img_path}")
          sh("curl -s -u #{opts[:user]}:#{opts[:password]} -k -T #{ctx.inst_data_dir}/metadata.iso https://#{opts[:host]}/folder/#{ctx.inst[:uuid]}/metadata.iso?dsName=#{opts[:datastore]}")
        ensure
          sh("rm -rf #{ctx.inst_data_dir}") rescue logger.warn($!.message)
        end
      end

      def check_interface(ctx)
        #TODO: Move interface creation here from esxi_local_store
      end

      def attach_volume_to_guest(ctx)
        raise NotImplementedError
      end

      def detach_volume_from_guest(ctx)
        raise NotImplementedError
      end

      def self.settings(ctx)
        if @esxi_options.nil?
          @esxi_options = {
            :host => Dcmgr::Configurations.hva.esxi_ipaddress,
            :user => Dcmgr::Configurations.hva.esxi_username,
            :password => Dcmgr::Configurations.hva.esxi_password,
            :insecure => Dcmgr::Configurations.hva.esxi_insecure,
            :datastore => Dcmgr::Configurations.hva.esxi_datastore,
            :datacenter => Dcmgr::Configurations.hva.esxi_datacenter,
          }

          @esxi_options.each { |k,v|
            raise "ESXi #{k} isn't set. Please set it in hva.conf" if v.nil?
          }
        end

        @esxi_options
      end

      private
      def find_vm(ctx)
        inst = ctx.inst

        vmname = inst[:uuid]

        opts = self.class.settings(ctx)

        vim = RbVmomi::VIM.connect opts
        dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or raise "datacenter [#{opts[:datacenter]}] not found"

        vm = dc.find_vm(vmname) or raise "VM [#{vmname}] not found"
      end
    end
  end
end
