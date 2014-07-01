# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LocalStore < Task::Tasklet
      helpers Task::LoggerHelper
      include Fuguta::Configuration::ConfigurationMethods

      def_configuration

      # download and prepare image files to ctx.os_devpath.
      def deploy_image(inst,ctx)
        raise NotImplementedError
      end

      # download backup object and setup single image file.
      def deploy_volume(hva_ctx, volume, backup_object, opts={})
        raise NotImplementedError
      end

      # create blank image file.
      def deploy_blank_volume(hva_ctx, volume, opts={})
        raise NotImplementedError
      end

      # delete an image file.
      def delete_volume(hva_ctx, volume)
        raise NotImplementedError
      end

      def upload_image(inst, ctx, bo, ev_callback)
        raise NotImplementedError
      end

      # upload volume as backup object.
      def upload_volume(ctx, bo, ev_callback)
        raise NotImplementedError
      end

      def self.driver_class(hypervisor_name)
        Hypervisor.driver_class(hypervisor_name).local_store_class
      end
    end
  end
end
