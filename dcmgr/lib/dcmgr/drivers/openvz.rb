# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class Openvz < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::Cgroup::CgroupContextProvider
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper
      include Dcmgr::Helpers::TemplateHelper
      
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
          if @subject.respond_to?(meth)
            @subject.send(meth, *args)
          else
            super
          end
        end
      end

      before do
        @args = @args.map {|i|  i.is_a?(Rpc::HvaContext) ? OvzContext.new(i) : i; }
        # First arugment is expected a HvaContext.
        @hc = @args.first
      end

      def run_instance(hc)
        # load openvz conf
        config = OpenvzConfig.new
        
        # write a openvz container id
        inst = hc.inst
        ctid_file_path = File.expand_path('openvz.ctid', hc.inst_data_dir)

        File.open(ctid_file_path, "w") { |f|
          f.write(hc.ctid)
        }
        logger.debug("write a openvz container id #{ctid_file_path}")
        
        # delete old config file
        config_file_path = "#{config.ve_config_dir}/#{hc.ctid}.conf"
        mount_file_path = "#{config.ve_config_dir}/#{hc.ctid}.mount"
        if File.exists?(config_file_path)
          File.unlink(config_file_path)
          logger.debug("old config file was deleted #{config_file_path}")
        end
        if File.exists?(mount_file_path)
          File.unlink(mount_file_path)
          logger.debug("old mount file was deleted #{mount_file_path}")
        end
        
        destroy_config_file_path = "#{config_file_path}.destroyed"
        destroy_mount_file_path = "#{mount_file_path}.destroyed"
        if File.exists?(destroy_config_file_path)
          File.unlink(destroy_config_file_path)
          logger.debug("old config file was deleted #{destroy_config_file_path}")
        end
        if File.exists?(destroy_mount_file_path)
          File.unlink(destroy_mount_file_path)
          logger.debug("old mount file was deleted #{destroy_config_file_path}")
        end
        
        # generate openvz config
        hypervisor = inst[:host_node][:hypervisor]
        output_file_path = "#{config.ve_config_dir}/ve-openvz.conf-sample"
        
        render_template('template.conf', output_file_path, binding)

        logger.debug("created config #{output_file_path}")
        
        # create openvz container
        private_folder = "#{config.ve_private}/#{hc.ctid}"
        image = inst[:image]
        case image[:file_format]
        when "tgz"
          # OpenvzLocalStore driver downloads the file under /vz/template/cache. it places the file without extention.
          # but "vzctl create" expects that the file name has the extension. so the line below creates hard link to
          # the path name with extention of archiver type.

          # remove existing 
          File.unlink(File.expand_path(image[:backup_object][:uuid] + ".tar.gz", config.template_cache)) rescue nil
          sh("ln %s %s", [File.expand_path(image[:backup_object][:uuid], config.template_cache),
                          File.expand_path(image[:backup_object][:uuid] + ".tar.gz", config.template_cache)])
          ostemplate = image[:backup_object][:uuid]
          # create vm and config file
          sh("vzctl create %s --ostemplate %s --config %s",[hc.ctid, ostemplate, hypervisor])
          logger.debug("created container #{private_folder}")
          logger.debug("created config #{config_file_path}")
        when "raw"
          # copy config file
          raise "config file does not exist #{output_file_path}" unless File.exists?(output_file_path)
          FileUtils.cp(output_file_path, config_file_path)
          # create mount directory
          FileUtils.mkdir(private_folder) unless File.exists?(private_folder)
          unless image[:root_device].nil?
            # creating loop devices
            mapdevs = sh("kpartx -av %s | egrep -v '^(gpt|dos):' | egrep ^add | awk '{print $3}'", [hc.os_devpath])
            new_device_file = mapdevs[:stdout].split("\n").map {|mapdev| "/dev/mapper/#{mapdev}"}
            #
            # add map loop2p1 (253:2): 0 974609 linear /dev/loop2 1
            # add map loop2p2 (253:3): 0 249856 linear /dev/loop2 974848
            #
            # wait udev queue
            sh("udevadm settle")
            # find loopback device
            k, v = image[:root_device].split(":")
            case k
            when "uuid","label"
            else
              raise "unknown root device mapping key #{k}"
            end
            search_word = "#{k.upcase}=#{v}"
            device_file_list = sh("blkid -t %s |awk '{print $1}'", [search_word])
            #
            # /dev/mapper/loop0p1: UUID="5eb668a7-176b-44ac-b0c0-ff808c191420" TYPE="ext4" 
            # /dev/mapper/loop2p1: UUID="5eb668a7-176b-44ac-b0c0-ff808c191420" TYPE="ext4"
            # /dev/mapper/ip-192.0.2.19:3260-iscsi-iqn.2010-09.jp.wakame:vol-lzt6zx5c-lun-1p1: UUID="148bc5df-3fc5-4e93-8a16-7328907cb1c0" TYPE="ext4"
            #
            device_file_list = device_file_list[:stdout].split(":\n")
            # root device
            root_device = new_device_file & device_file_list
            raise "root device does not exist #{image[:root_device]}" if root_device.empty?
            sh("mount %s %s", [root_device[0], private_folder])

            # Write root partition identifier to instance data dir for the failure recovery script
            File.open(File.expand_path('root_partition', hc.inst_data_dir), 'w') {|f| f.puts(search_word) }
          else
            cmd = "mount %s %s"
            args = [hc.os_devpath, private_folder]
            if image[:boot_dev_type] == 2
              cmd += " -o loop"
            end
            # mount vm image file
            sh(cmd, args)
          end
        end
        
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
            if vif[:ipv4] && vif[:ipv4][:network]
              bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
              sh("vzctl set %s --netif_add %s,%s,%s,%s,%s --save",[hc.inst_id, ifname, mac, host_ifname, host_mac, bridge])
            end
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
        
        # mount metadata drive
        hn_metadata_path = "#{hc.config.ve_root}/#{hc.ctid}/metadata"
        ve_metadata_path = "#{hc.inst_data_dir}/metadata"
        FileUtils.mkdir(ve_metadata_path) unless File.exists?(ve_metadata_path)
        raise "metadata image does not exist #{hc.metadata_img_path}" unless File.exists?(hc.metadata_img_path)
        res = sh("kpartx -av %s", [hc.metadata_img_path])
        if res[:stdout] =~ /^add map (\w+) /
          lodev="/dev/mapper/#{$1}"
        else
          raise "Unexpected result from kpartx: #{res[:stdout]}"
        end
        sh("udevadm settle")
        # save the loop device name for the metadata drive.
        File.open(File.expand_path('metadata.lodev', hc.inst_data_dir), 'w') {|f| f.puts(lodev) }
        sh("mount -o ro %s %s", [lodev, ve_metadata_path])
        
        # generate openvz mount config
        render_template('template.mount', hc.ct_mount_path, binding)
        render_template('template.umount', hc.ct_umount_path, binding)
        sh("chmod +x %s", [hc.ct_umount_path])
        sh("chmod +x %s", [hc.ct_mount_path])
        hc.logger.info("Created config #{mount_file_path}")
        
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
        
        case hc.inst[:image][:file_format]
        when "raw"
          # umount vm image directory
          raise "private directory does not exist #{hc.private_dir}" unless File.directory?(hc.private_dir)
          sh("umount -l %s", [hc.private_dir])
          hc.logger.debug("unmounted private directory #{hc.private_dir}")
          if hc.inst[:image][:root_device]
            detach_loop(hc.os_devpath)
          end
        end

        # umount metadata drive
        #
        # *** Don't use "-l" option. ***
        # If "-l" option is added, umount command will get following messages.
        # > device-mapper: remove ioctl failed: Device or resource busy
        # > ioctl: LOOP_CLR_FD: Device or resource busy
        #
        sh("umount %s/metadata", [hc.inst_data_dir])
        detach_loop(hc.metadata_img_path)
        hc.logger.info("Umounted metadata directory #{hc.inst_data_dir}/metadata")
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


    end
  end
end
