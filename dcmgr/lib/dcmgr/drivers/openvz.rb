# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class Openvz < Hypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper
      include Dcmgr::Helpers::TemplateHelper
      
      def run_instance(hc)
        # load openvz conf
        config = OpenvzConfig.new
        
        # write a openvz container id
        inst = hc.inst
        inst_data_dir = hc.inst_data_dir
        ctid_file_path = File.expand_path('openvz.ctid', inst_data_dir)
        ctid = inst[:id]
        
        File.open(ctid_file_path, "w") { |f|
          f.write(ctid)
        }
        logger.debug("write a openvz container id #{ctid_file_path}")

        # generate openvz config
        hypervisor = inst[:host_node][:hypervisor]
        template_file_path = File.expand_path("../../templates/#{hypervisor}/template.conf", __FILE__)
        output_file_path = "#{config.ve_config_dir}/ve-openvz.conf-sample"
        
        render_template(template_file_path, output_file_path) do
          binding
        end
        
        # create openvz container
        private_folder = "#{config.ve_private}/#{ctid}"
        config_file_path = "#{config.ve_config_dir}/#{ctid}.conf" 
        image = inst[:image]
        case image[:format]
        when "tgz"
          ostemplate = File.basename(image[:source][:uri], ".tar.gz")
          # create vm and config file
          sh("vzctl create %s --ostemplate %s --config %s",[ctid, ostemplate, hypervisor])
          logger.debug("created container #{private_folder}")
          logger.debug("created config #{config_file_path}")
        when "raw"
          # copy config file
          FileUtils.cp(output_file_path, config_file_path)
          # create mount directory
          FileUtils.mkdir(private_folder) unless File.exists?(private_folder)
          cmd = "mount %s %s"
          args = [hc.os_devpath, private_folder]
          if image[:boot_dev_type] == 2
            cmd += " -o loop"
          end
          # mount vm image file
          sh(cmd, args)
        end
        
        # setup openvz config file
        inst_spec = inst[:instance_spec]
        vifs = inst[:vif]
        
        # set virtual interface
        if !vifs.empty?
          vifs.sort {|a, b| a[:device_index] <=> b[:device_index]}.each {|vif|
            ifname = "eth#{vif[:device_index]}"
            mac = vif[:mac_addr].unpack('A2'*6).join(':')
            host_ifname = vif[:uuid]
            bridge = vif[:network][:link_interface]
            sh("vzctl set %s --netif_add %s,%s,%s,%s,%s --save",[ctid, ifname, mac, host_ifname, mac, bridge])
          }
        end
        # set cpus
        sh("vzctl set %s --cpus %s --save",[ctid, inst_spec[:cpu_cores]])
        # set memory size
        sh("vzctl set %s --privvmpage %s --save",[ctid, (inst_spec[:memory_size] * 256)])
        sh("vzctl set %s --vmguarpages %s --save",[ctid, (inst_spec[:memory_size] * 256)])
        
        # setup metadata drive
        hn_metadata_path = "#{config.ve_root}/#{ctid}/metadata"
        ve_metadata_path = "#{inst_data_dir}/metadata"
        metadata_img_path = hc.metadata_img_path
        FileUtils.mkdir(ve_metadata_path) unless File.exists?(ve_metadata_path)
        sh("mount -o loop -o ro %s %s", [metadata_img_path, ve_metadata_path])
        logger.debug("mount #{metadata_img_path} to #{ve_metadata_path}")
        
        # generate openvz mount config
        template_mount_file_path = File.expand_path("../../templates/#{hypervisor}/template.mount", __FILE__)
        output_mount_file_path = "#{config.ve_config_dir}/#{ctid}.mount"
        
        render_template(template_mount_file_path, output_mount_file_path) do
          binding
        end
        sh("chmod +x %s", [output_mount_file_path])
        logger.debug("created config #{output_mount_file_path}")
        
        # start openvz container
        sh("vzctl start %s",[ctid])
        logger.debug("start container #{ctid}")
        sleep 1
        
        # add vifs to bridge
        add_vifs(vifs)
      end

      def terminate_instance(hc)
        # load openvz conf
        config = OpenvzConfig.new
        
        # openvz container id
        ctid = hc.inst[:id]

        # stop container
        sh("vzctl stop %s",[ctid])
        case hc.inst[:image][:format]
        when "raw"
          sh("umount %s/%s",[config.ve_private, ctid])
        end
        sh("umount %s/metadata", [hc.inst_data_dir])
        logger.debug("stop container #{ctid}")

        # delete container folder
        sh("vzctl destroy %s",[ctid])
        sh("rm %s/%s.conf.destroyed",[config.ve_config_dir, ctid])
        sh("rm %s/%s.mount.destroyed",[config.ve_config_dir, ctid])
        logger.debug("delete container folder #{config.ve_private}/#{ctid}")
      end
      
      def reboot_instance(hc)
        # openvz container id
        ctid = hc.inst[:id]
        
        # reboot container
        sh("vzctl restart %s", [ctid])
        logger.debug("restart container #{ctid}")
        
        # add vifs to bridge
        add_vifs(hc.inst[:vif])
      end

      private
      def add_vifs(vifs)
        vifs.each {|vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            sh("/usr/sbin/brctl addif %s %s", [vif[:ipv4][:network][:link_interface], vif[:uuid]])
            logger.debug("add virtual interface #{vif[:ipv4][:network][:link_interface]} to #{vif[:uuid]}")
          end
        }
      end
    end
  end
end
