# -*- coding: utf-8 -*-

require 'fileutils'

module Dcmgr
  module Drivers
    # Abstract class for Linux based hypervisors.
    class LinuxHypervisor < Hypervisor
      include Dcmgr::Helpers::NicHelper
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::TemplateHelper
      include Dcmgr::Helpers::BlockDeviceHelper

      template_base_dir 'linux'

      METADATA_DRIVE_DEFS = {
        'ext4' => {:format=>'ext4', :label_opt=>'-L'},
        'vfat' => {:format=>'vfat', :label_opt=>'-n'},
      }
      METADATA_DRIVE_FORMAT='vfat'

      def_configuration do
        # TODO: create helper method to
        # Abstract class for Cgroup parameters
        self.const_set(:Cgroup, Class.new(Fuguta::Configuration))

        self.const_set(:CgroupBlkio, Class.new(self.const_get(:Cgroup)))
        self.const_get(:CgroupBlkio).module_eval do
          param :enable_throttling, :default=>false

          # Modifiable throttle parameters for blkio controller.
          # It is ignored if the value is either nil or 0.

          # blkio.throttle.read_iops_device
          param :read_iops, :default=>nil
          # blkio.throttle.read_bps_device
          param :read_bps, :default=>nil
          # blkio.throttle.write_iops_device
          param :write_iops, :default=>nil
          # blkio.throttle.write_bps_device
          param :write_bps, :default=>nil
          # blkio.weight & blkio.weight_device
          param :weight, :default=>nil
        end

        DSL do
          def cgroup_blkio(&blk)
            @config[:cgroup_blkio].parse_dsl(&blk)
          end
        end

        on_initialize_hook do
          @config[:cgroup_blkio] = LinuxHypervisor::Configuration::CgroupBlkio.new(self)
        end
      end

      def check_interface(hc)
        hc.inst[:instance_nics].each { |vnic|
          next if vnic[:network].nil?

          network = hc.rpc.request('hva-collector', 'get_network', vnic[:network_id])

          unless network[:dc_network][:name].nil?
            raise "Dc network missing in database"
          end
          
          network_name = network[:dc_network][:name]
          dcn = Dcmgr::Configurations.hva.dc_networks[network_name]
          if dcn.nil?
            raise "Missing local configuration for the network: #{network_name}"
          end
          unless valid_nic?(dcn.interface)
            raise "Interface not found for the network #{network_name}: #{dcn.interface}"
          end
          unless valid_nic?(dcn.bridge)
            raise "Bridge not found for the network #{network_name}: #{dcn.bridge}"
          end

          fwd_if = dcn.interface
          bridge_if = dcn.bridge

          if network[:dc_network][:vlan_lease]
            fwd_if = vif_uuid("#{dcn.interface}.#{network[:dc_network][:vlan_lease][:tag_id]}")
            bridge_if = network[:dc_network][:uuid]
            unless valid_nic?(fwd_if)
              sh("/sbin/vconfig add #{phy_if} #{network[:vlan_id]}")
              sh("/sbin/ip link set %s up", [fwd_if])
              sh("/sbin/ip link set %s promisc on", [fwd_if])
            end

            # create new bridge only when the vlan is assigned to customer.
            unless valid_nic?(bridge_if)
              sh(add_bridge_cmd)
              sh(minimize_stp_forward_delay(bridge_if))
              # There is null case for the forward interface to create closed bridge network.
              if fwd_if
                sh(attach_vif_to_bridge(bridge_if, fwd_if))
              end
            end
          end
        }
        sleep 1
      end

      def setup_metadata_drive(hc,metadata_items)
        begin
          FileUtils.mkdir(hc.inst_data_dir) unless File.exists?(hc.inst_data_dir)

          logger.info("Setting up metadata drive image:#{hc.inst_id}")
          # truncate creates sparsed file.
          sh("/usr/bin/truncate -s 10m '#{hc.metadata_img_path}'; sync;")
          sh("parted %s < %s", [hc.metadata_img_path, LinuxHypervisor.template_real_path('metadata.parted')])
          res = sh("kpartx -av %s", [hc.metadata_img_path])
          if res[:stdout] =~ /^add map (\w+) /
            lodev="/dev/mapper/#{$1}"
          else
            raise "Unexpected result from kpartx: #{res[:stdout]}"
          end
          sh("udevadm settle")
          sh("mkfs -t #{METADATA_DRIVE_DEFS[METADATA_DRIVE_FORMAT][:format]} #{METADATA_DRIVE_DEFS[METADATA_DRIVE_FORMAT][:label_opt]} METADATA %s", [lodev])
          Dir.mkdir("#{hc.inst_data_dir}/tmp") unless File.exists?("#{hc.inst_data_dir}/tmp")
          sh("/bin/mount -t #{METADATA_DRIVE_DEFS[METADATA_DRIVE_FORMAT][:format]} #{lodev} '#{hc.inst_data_dir}/tmp'")

          # build metadata directory tree
          metadata_base_dir = File.expand_path("meta-data", "#{hc.inst_data_dir}/tmp")
          FileUtils.mkdir_p(metadata_base_dir)

          metadata_items.each { |k, v|
            if k[-1,1] == '/' && v.nil?
              # just create empty folder
              FileUtils.mkdir_p(File.expand_path(k, metadata_base_dir))
              next
            end

            dir = File.dirname(k)
            if dir != '.'
              FileUtils.mkdir_p(File.expand_path(dir, metadata_base_dir))
            end
            File.open(File.expand_path(k, metadata_base_dir), 'w') { |f|
              f.puts(v.to_s)
            }
          }
          # user-data
          File.open(File.expand_path('user-data', "#{hc.inst_data_dir}/tmp"), 'w') { |f|
            f.puts(hc.inst[:user_data])
          }
        ensure
          shell.run!("/bin/umount -l %s", ["#{hc.inst_data_dir}/tmp"]) rescue logger.warn($!.message)
          detach_loop(hc.metadata_img_path)
        end
      end

      def iscsi_target_dev_path(volume_hash)
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{volume_hash[:volume_device][:iscsi_storage_node][:ip_address]}:3260",
                                                     volume_hash[:volume_device][:iqn],
                                                     volume_hash[:volume_device][:lun]]
      end

      def attach_volume_to_host(ctx, volume_id)
        vol = ctx.inst[:volume][volume_id]
        raise "Unknown volume_id is specified: #{volume_id}" if vol.nil?

        if vol[:volume_type] == 'Dcmgr::Models::IscsiVolume'
          tryagain do
            next true if File.exist?(iscsi_target_dev_path(vol))

            # Auto discovery
            #sh("iscsiadm --mode discovery -t sendtargets --portal '%s'",
            #   [vol[:volume_device][:iscsi_storage_node][:ip_address]])
            # Manual discovery
            sh("iscsiadm --mode node --op new --targetname '%s' --portal '%s'",
               [vol[:volume_device][:iqn], vol[:volume_device][:iscsi_storage_node][:ip_address]])
            # disable auto mount after unexpected system reboot.
            sh("iscsiadm --mode node --op update --targetname '%s' --portal '%s' -n node.startup -v manual",
               [vol[:volume_device][:iqn], vol[:volume_device][:iscsi_storage_node][:ip_address]])
            sh("iscsiadm --mode node --targetname '%s' --portal '%s' --login",
               [vol[:volume_device][:iqn], vol[:volume_device][:iscsi_storage_node][:ip_address]])
          end
          # wait udev queue
          sh("/sbin/udevadm settle")
        end
      end

      def detach_volume_from_host(ctx, volume_id)
        vol = ctx.inst[:volume][volume_id]
        raise "Unknown volume_id is specified: #{volume_id}" if vol.nil?

        if vol[:volume_type] == 'Dcmgr::Models::IscsiVolume'
          tryagain do
            next true unless File.exist?(iscsi_target_dev_path(vol))

            # iscsi logout
            sh("iscsiadm --mode node --targetname '%s' --portal '%s' --logout",
               [vol[:volume_device][:iqn], vol[:volume_device][:iscsi_storage_node][:ip_address]])
            sh("iscsiadm --mode node --op delete --target '%s' --portal '%s'",
               [vol[:volume_device][:iqn], vol[:volume_device][:iscsi_storage_node][:ip_address]])
          end
          # wait udev queue
          sh("/sbin/udevadm settle")
        end
      end

      protected

      # cgroup_set('blkio', "0") do
      #   add('blkio.throttle.read_iops_device', "253:0 128000")
      # end
      def cgroup_set(subsys, scope, &blk)
        if driver_configuration.cgroup_blkio.enable_throttling == false
          return
        end
        cgroup_mnt = `findmnt -n -t cgroup -O "#{subsys}"`.split("\n").first
        raise "Failed to find the cgroup base path to #{subsys} controller." if cgroup_mnt.nil?
        cgroup_base = cgroup_mnt.split(/\s+/).first

        cgroup_scope = File.expand_path(scope, cgroup_base)
        unless File.directory?(cgroup_scope)
          raise "Unknown directory in the cgroup #{subsys}: #{cgroup_scope}"
        end

        dsl = CgroupBlkio.new(cgroup_scope)
        if blk.arity == 1
          blk.call(dsl)
        else
          dsl.instance_eval(&blk)
        end
      end

      class CgroupBlkio
        def initialize(cgroup_scope)
          @cgroup_scope = cgroup_scope
        end

        def add(k, v)
          path = File.join(@cgroup_scope, k)
          File.open(path, 'w+') { |f|
            f.puts(v)
          }
        end

        def find_devnode_id(src)
          devnode_id=`lsblk -n -r -d $(df -P '#{src}' | sed -e '1d' | awk '{print $1}') | awk '{print $3}'`
          unless $?.success?
            raise "Failed to find devnode ID (MAJOR:MINOR) from #{src}"
          end

          devnode_id.chomp
        end
      end

    end
  end
end
