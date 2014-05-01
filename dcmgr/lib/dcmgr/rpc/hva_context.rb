# -*- coding: utf-8 -*-

require 'logger'
require 'isono'

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
        if @hva.instance_variable_get(:@os_devpath)
          return @hva.instance_variable_get(:@os_devpath)
        end
        
        boot_vol = inst[:volume][inst[:boot_volume_id]]
        raise "Unknown boot volume details: #{inst[:boot_volume_id]}" if boot_vol.nil?

        volume_path(boot_vol)
      end

      def volume_path(volume_hash)
        case volume_hash[:volume_type]
        when 'Dcmgr::Models::LocalVolume'
          # TODO: more supports for mount label names.
          case volume_hash[:volume_device][:mount_label]
          when 'instance'
            File.join(self.inst_data_dir, volume_hash[:volume_device][:path])
          else
            raise "Unsupoorted mount label: #{volume_hash[:volume_device][:mount_label]}"
          end
        when 'Dcmgr::Models::IscsiVolume'
          hypervisor_driver_class.new.iscsi_target_dev_path(volume_hash)
        when 'Dcmgr::Models::NfsVolume'
          File.join(volume_hash[:volume_device][:nfs_storage_node][:mount_point], volume_hash[:volume_device][:path])
        else
          raise "Unsupported volume type: #{volume_hash[:volume_type]}"
        end
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

      # Save instance/VM parameter as plane file under inst_data_dir().
      #
      # For reading from shell script, "\n" is inserted to end of buffer.
      def dump_instance_parameter(rel_path, buf)
        # ignore error when try to put file to deleted instance.
        return self unless File.directory?(self.inst_data_dir())
        
        File.open(File.expand_path(rel_path, self.inst_data_dir()), 'w'){ |f|
          f.puts(buf)
        }
        self
      end

      class InstanceLogger
        def initialize(hva_context)
          @hva_context = hva_context
          require 'logger'
          @logger = ::Logger.new(Dcmgr::Logger.log_io)
          @logger.progname = 'HvaHandler'
        end

        ["fatal", "error", "warn", "info", "debug"].each do |level|
          define_method(level){|msg|
            # key from Isono::NodeModules::JobWorker::JOB_CTX_KEY
            jobctx = Thread.current[:job_worker_ctx] || raise("Failed to get JobContext from current thread #{Thread.current}")
            @logger.__send__(level, "Session ID: #{jobctx.session_id}: Instance UUID: #{@hva_context.inst_id}: #{msg}")
          }
        end
      end

    end
  end
end
