# -*- coding: utf-8 -*-

require 'fileutils'

module Dcmgr
  module Drivers
    class KvmLocalStore < LinuxLocalStore
      include Dcmgr::Logger
      include Fuguta::Configuration::ConfigurationMethods

      def_configuration do
        # Set extra parameters to -drive qemu option.
        param :drive_extra_options, :default=>'cache=none,aio=native'

        def validate(errors)
          if @config[:drive_extra_options] =~ /\s/
            errors << "drive_extra_options can not include white space."
          elsif @config[:drive_extra_options] == ''
            @config[:drive_extra_options] = nil
          end
        end
      end

      # download and setup single image file.
      def deploy_blank_volume(hva_ctx, volume, opts={})
        @ctx = hva_ctx
        FileUtils.mkdir(@ctx.inst_data_dir) unless File.exists?(@ctx.inst_data_dir)

        # assume volume_device is LocalVolume.
        volume_path = File.expand_path(volume[:volume_device][:path], @ctx.inst_data_dir)

        sh("qemu-img create -f qcow2 '#{volume_path}' '#{volume[:size]}'")
      end

    end
  end
end
