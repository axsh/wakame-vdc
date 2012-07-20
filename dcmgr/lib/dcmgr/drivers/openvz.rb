# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class Openvz < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper
      include Dcmgr::Helpers::TemplateHelper
      
      template_base_dir "openvz"
      
      def run_instance(hc)
        # load openvz conf
        config = OpenvzConfig.new
        
        # write a openvz container id
        inst = hc.inst
        inst_id = hc.inst_id
        inst_data_dir = hc.inst_data_dir
        ctid_file_path = File.expand_path('openvz.ctid', inst_data_dir)
        ctid = inst[:id]

        File.open(ctid_file_path, "w") { |f|
          f.write(ctid)
        }
        logger.debug("write a openvz container id #{ctid_file_path}")
        
        # delete old config file
        config_file_path = "#{config.ve_config_dir}/#{ctid}.conf" 
        mount_file_path = "#{config.ve_config_dir}/#{ctid}.mount"
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
        private_folder = "#{config.ve_private}/#{ctid}"
        image = inst[:image]
        case image[:file_format]
        when "tgz"
          ostemplate = File.basename(image[:backup_object][:uri], ".tar.gz")
          # create vm and config file
          sh("vzctl create %s --ostemplate %s --config %s",[ctid, ostemplate, hypervisor])
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
            new_device_file = sh("kpartx -a -s -v %s", [hc.os_devpath])
            #
            # add map loop2p1 (253:2): 0 974609 linear /dev/loop2 1
            # add map loop2p2 (253:3): 0 249856 linear /dev/loop2 974848
            #
            # wait udev queue
            sh("udevadm settle")
            # loopback device file
            new_device_file = new_device_file[:stdout].split(nil).grep(/p[0-9]+p[0-9]+/).collect {|w| "/dev/mapper/#{w}"} 
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
            #
            device_file_list = device_file_list[:stdout].split(":\n")
            # root device
            root_device = new_device_file & device_file_list
            raise "root device does not exits #{image[:root_device]}" if root_device.empty?
            sh("mount %s %s", [root_device[0], private_folder])
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
        sh("vzctl set %s --name %s --save",[ctid, inst_id])
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
            bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
            sh("vzctl set %s --netif_add %s,%s,%s,%s,%s --save",[inst_id, ifname, mac, host_ifname, host_mac, bridge])
            #
            # NETIF="ifname=eth0,bridge=vzbr0,mac=52:54:00:68:BB:AC,host_ifname=vif-h63jg7pp,host_mac=52:54:00:68:BB:AC"
            #
          }
        end
        # set cpus
        sh("vzctl set %s --cpus %s --save",[inst_id, inst[:cpu_cores]])
        #
        # CPUS="1"
        #
        
        # set memory size
        sh("vzctl set %s --privvmpage %s --save",[inst_id, (inst[:memory_size] * 256)])
        #
        # PRIVVMPAGES="65536"
        #
        sh("vzctl set %s --vmguarpages %s --save",[inst_id, (inst[:memory_size] * 256)])
        #
        # VMGUARPAGES="65536"
        # 
        
        # setup metadata drive
        hn_metadata_path = "#{config.ve_root}/#{ctid}/metadata"
        ve_metadata_path = "#{inst_data_dir}/metadata"
        metadata_img_path = hc.metadata_img_path
        FileUtils.mkdir(ve_metadata_path) unless File.exists?(ve_metadata_path)
        raise "metadata image does not exist #{metadata_img_path}" unless File.exists?(metadata_img_path)
        sh("mount -o loop -o ro %s %s", [metadata_img_path, ve_metadata_path])
        logger.debug("mount #{metadata_img_path} to #{ve_metadata_path}")
        
        # generate openvz mount config
        render_template('template.mount', mount_file_path, binding)
        sh("chmod +x %s", [mount_file_path])
        logger.debug("created config #{mount_file_path}")
        
        # start openvz container
        sh("vzctl start %s",[inst_id])
        logger.debug("start container #{inst_id}")
        sleep 1
        
      end

      def terminate_instance(hc)
        # load openvz conf
        config = OpenvzConfig.new
        
        # openvz container id
        ctid = hc.inst[:id]
        
        # openvz container name
        inst_id = hc.inst_id
        
        # container directory
        private_dir = "#{config.ve_private}/#{ctid}"
        
        # stop container
        sh("vzctl stop %s",[inst_id])

        # wait stopped of container status
        tryagain do
          sh("vzctl status %s", [inst_id])[:stdout].chomp.include?("down")
        end
        logger.debug("stop container #{inst_id}")
        
        case hc.inst[:image][:file_format]
        when "raw"
          # umount vm image directory
          raise "private directory does not exist #{private_dir}" unless File.directory?(private_dir)
          sh("umount -d %s", [private_dir])
          logger.debug("unmounted private directory #{private_dir}")
          if hc.inst[:image][:root_device]
            # delete device maps
            img_file_path = "#{hc.inst_data_dir}/#{inst_id}"
            sh("kpartx -d -s -v %s", [img_file_path])
            # wait udev queue
            sh("udevadm settle")
          end
        end
        sh("umount -d %s/metadata", [hc.inst_data_dir])
        logger.debug("unmounted metadata directory #{hc.inst_data_dir}/metadata")
        
        # delete container folder
        sh("vzctl destroy %s",[inst_id])
        logger.debug("delete container folder #{private_dir}")
        # delete config file and mount file
        container_config = "#{config.ve_config_dir}/#{ctid}"
        config_file_path = "#{container_config}.conf.destroyed"
        mount_file_path = "#{container_config}.mount.destroyed"
        raise "config file does not exist #{config_file_path}" unless File.exist?(config_file_path)
        raise "mount file does not exist #{mount_file_path}" unless File.exist?(mount_file_path)

        File.unlink(config_file_path, mount_file_path)
        logger.debug("delete config file #{config_file_path}")
        logger.debug("delete mount file #{mount_file_path}")
      end
      
      def reboot_instance(hc)
        # openvz container name
        inst_id = hc.inst_id
        
        # reboot container
        sh("vzctl restart %s", [inst_id])
        logger.debug("restart container #{inst_id}")
        
      end

      def poweroff_instance(hc)
        sh("vzctl stop %s", [hc.inst_id])
      end

      def poweron_instance(hc)
        sh("vzctl start %s", [hc.inst_id])
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
