# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class Openvz < LinuxContainer
      include Dcmgr::Logger
      include Dcmgr::Helpers::NicHelper

      template_base_dir "openvz"

      def_configuration do
        param :ctid_offset, :default=>100

        def validate(errors)
          if @config[:ctid_offset].to_i < 100
            errors << "ctid_offset must be larger than or equal to 100: #{@config[:ctid_offset]}"
          end
        end
      end

      # Decorator pattern class of Rpc::HvaHandler::HvaContext.
      class OvzContext
        def initialize(root_ctx)
          raise ArgumentError unless root_ctx.is_a?(Rpc::HvaContext)
          @subject = root_ctx
          @ovz_config = OpenvzConfig.new
        end

        attr_reader :ovz_config
        alias :config :ovz_config

        def ctid
          Drivers::Openvz.driver_configuration.ctid_offset + inst[:id].to_i
        end

        def private_dir
          File.expand_path(ctid.to_s, config.ve_private)
        end

        def ct_umount_path
          File.expand_path("#{ctid}.umount", config.ve_config_dir)
        end

        def ct_mount_path
          File.expand_path("#{ctid}.mount", config.ve_config_dir)
        end

        def ct_conf_path
          File.expand_path("#{ctid}.conf", config.ve_config_dir)
        end

        def ct_local_confs
          [ct_conf_path, ct_mount_path, ct_umount_path]
        end

        def cgroup_scope
          ctid.to_s
        end

        private
        def method_missing(meth, *args)
          @subject.send(meth, *args)
        end
      end

      before do
        @args = @args.map {|i|  i.is_a?(Rpc::HvaContext) ? OvzContext.new(i) : i; }
        # First arugment is expected a HvaContext.
        @hc = @args.first
      end

      def run_instance(hc)
        # write a openvz container id
        inst = hc.inst
        ctid_file_path = File.expand_path('openvz.ctid', hc.inst_data_dir)

        File.open(ctid_file_path, "w") { |f|
          f.write(hc.ctid)
        }
        logger.debug("write a openvz container id #{ctid_file_path}")

        # delete old config file
        if File.exists?(hc.ct_conf_path)
          File.unlink(hc.ct_conf_path)
          logger.debug("old config file was deleted #{hc.ct_conf_path}")
        end
        if File.exists?(hc.ct_mount_path)
          File.unlink(hc.ct_mount_path)
          logger.debug("old mount file was deleted #{hc.ct_mount_path}")
        end

        destroy_config_file_path = "#{hc.ct_conf_path}.destroyed"
        destroy_mount_file_path = "#{hc.ct_mount_path}.destroyed"
        if File.exists?(destroy_config_file_path)
          File.unlink(destroy_config_file_path)
          logger.debug("old config file was deleted #{destroy_config_file_path}")
        end
        if File.exists?(destroy_mount_file_path)
          File.unlink(destroy_mount_file_path)
          logger.debug("old mount file was deleted #{destroy_config_file_path}")
        end

        # generate openvz config files
        generate_config(hc)

        # create openvz container
        image = inst[:image]
        # create mount directory
        FileUtils.mkdir(hc.private_dir) unless File.exists?(hc.private_dir)
        mount_root_image(hc, hc.private_dir)

        # mount metadata drive
        metadata_path = "#{hc.inst_data_dir}/metadata"
        Dir.mkdir(metadata_path) unless File.exists?(metadata_path)
        mount_metadata_drive(hc, metadata_path)

        # set name
        sh("vzctl set %s --name %s --save",[hc.ctid, hc.inst_id])
        #
        # Name="i-xxxx"
        #

        # setup openvz config file
        vifs = inst[:vif]

        # set virtual interface
        if !vifs.empty?
          vifs.sort {|a, b| a[:device_index] <=> b[:device_index]}.each {|vif|
            ifname = "eth#{vif[:device_index]}"
            mac = vif[:mac_addr].unpack('A2'*6).join(':')
            host_ifname = vif[:uuid]
            # host_mac become a randomly generated MAC Address.
            host_mac = nil
            bridge = nil

            if vif[:ipv4] && vif[:ipv4][:network]
              bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
            end

            sh("vzctl set %s --netif_add %s,%s,%s,%s,%s --save",[hc.inst_id, ifname, mac, host_ifname, host_mac, bridge])

            #
            # NETIF="ifname=eth0,bridge=vzbr0,mac=52:54:00:68:BB:AC,host_ifname=vif-h63jg7pp,host_mac=52:54:00:68:BB:AC"
            #
          }
        end
        # set cpus
        sh("vzctl set %s --cpus %s --save",[hc.inst_id, inst[:cpu_cores]])
        #
        # CPUS="1"
        #

        # set memory size
        sh("vzctl set %s --privvmpage %s --save",[hc.inst_id, (inst[:memory_size] * 256)])
        #
        # PRIVVMPAGES="65536"
        #
        sh("vzctl set %s --vmguarpages %s --save",[hc.inst_id, (inst[:memory_size] * 256)])
        #
        # VMGUARPAGES="65536"
        #

        # start openvz container
        sh("vzctl start %s",[hc.inst_id])
        hc.logger.info("Started container")

        # Set blkio throttling policy to vm_data_dir block device.
        cgroup_set('blkio', hc.cgroup_scope) do |c|
          devid = c.find_devnode_id(hc.inst_data_dir)

          c.add('blkio.throttle.read_iops_device', "#{devid} #{driver_configuration.cgroup_blkio.read_iops.to_i}")
          c.add('blkio.throttle.read_bps_device', "#{devid} #{driver_configuration.cgroup_blkio.read_bps.to_i}")
          c.add('blkio.throttle.write_iops_device', "#{devid} #{driver_configuration.cgroup_blkio.write_iops.to_i}")
          c.add('blkio.throttle.write_bps_device', "#{devid} #{driver_configuration.cgroup_blkio.write_bps.to_i}")
        end
      end

      def terminate_instance(hc)
        poweroff_instance(hc)

        # delete container folder
        sh("vzctl destroy %s",[hc.inst_id])
        hc.logger.debug("delete container folder #{hc.private_dir}")
        # delete CT local config files
        hc.ct_local_confs.map { |i| i + ".destroyed" }.each { |i|
          if File.exist?(i)
            File.unlink(i) rescue nil
            hc.logger.info("Deleted CT config: #{File.basename(i)}")
          else
            hc.logger.warn("#{File.basename(i)} does not exist")
          end
        }

        hc.logger.info("Terminated successfully.")
      end

      def reboot_instance(hc)
        # reboot container
        sh("vzctl restart %s", [hc.inst_id])
        hc.logger.info("Restarted container.")
      end

      def poweroff_instance(hc)
        # stop container
        sh("vzctl stop %s",[hc.inst_id])

        # wait stopped of container status
        tryagain do
          sh("vzctl status %s", [hc.inst_id])[:stdout].chomp.include?("down")
        end
        hc.logger.info("Stop container.")

        umount_root_image(hc, hc.private_dir)
        umount_metadata_drive(hc, File.expand_path('metadata', hc.inst_data_dir))
      end

      def poweron_instance(hc)
        run_instance(hc)
      end

      def check_instance(i)
        container_status = `vzctl status #{i}`.chomp.split(" ")[4]
        if container_status != "running"
          raise "Unable to find the openvz container: #{i}"
        end
      end

      private
      def generate_config(hc)
        # generate openvz config
        output_file_path = "#{hc.config.ve_config_dir}/ve-openvz.conf-sample"
        render_template('template.conf', output_file_path, binding)
        raise "config file does not exist #{output_file_path}" unless File.exists?(output_file_path)
        FileUtils.cp(output_file_path, hc.ct_conf_path)
        logger.debug("created config #{output_file_path}")

        # template variables
        ve_metadata_path = "#{hc.inst_data_dir}/metadata"
        hn_metadata_path = "#{hc.config.ve_root}/#{hc.ctid}/metadata"
        
        render_template('template.mount', hc.ct_mount_path, binding)
        render_template('template.umount', hc.ct_umount_path, binding)
        sh("chmod +x %s", [hc.ct_umount_path])
        sh("chmod +x %s", [hc.ct_mount_path])
        hc.logger.info("Created CT config: #{hc.ct_mount_path}")
      end

       Task::Tasklet.register(self.new)
    end
  end
end
