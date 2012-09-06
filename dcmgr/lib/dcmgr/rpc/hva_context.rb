# -*- coding: utf-8 -*-

require 'logger'

module Dcmgr
  module Rpc
    class HvaContext

      def initialize(subject)
        unless [HvaHandler, LocalStoreHandler].member?(subject.class)
          raise "Invalid Class: #{subject.class}"
        end
        @hva = subject
      end

      def node
        @hva.instance_variable_get(:@node)
      end

      def inst_id
        @hva.instance_variable_get(:@inst_id)
      end

      def inst
        @hva.instance_variable_get(:@inst)
      end

      def os_devpath
        @hva.instance_variable_get(:@os_devpath) || File.expand_path(self.inst[:uuid], self.inst_data_dir)
      end

      def metadata_img_path
        File.expand_path('metadata.img', inst_data_dir)
      end

      def vol
        @hva.instance_variable_get(:@vol)
      end

      def rpc
        @hva.rpc
      end

      def inst_data_dir
        File.expand_path("#{inst_id}", Dcmgr.conf.vm_data_dir)
      end

      def hypervisor_driver_class
        Drivers::Hypervisor.driver_class(inst[:host_node][:hypervisor])
      end

      def logger
        @instance_logger = InstanceLogger.new(self)
      end

      class InstanceLogger
        def initialize(hva_context)
          @hva_context = hva_context
          @logger = ::Logger.new(Dcmgr::Logger.default_logdev)
          @logger.progname = 'HvaHandler'
        end

        ["fatal", "error", "warn", "info", "debug"].each do |level|
          define_method(level){|msg|
            @logger.__send__(level, "Instance UUID: #{@hva_context.inst_id}: #{msg}")
          }
        end
      end

    end
  end
end
