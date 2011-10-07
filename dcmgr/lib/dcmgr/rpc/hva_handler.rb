# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc
    class HvaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      def select_hypervisor
        @hv = Dcmgr::Drivers::Hypervisor.select_hypervisor(@inst[:instance_spec][:hypervisor])
      end

      def attach_volume_to_host
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        tryagain do
          next true if File.exist?(@os_devpath)

          sh("iscsiadm -m discovery -t sendtargets -p %s", [@vol[:storage_node][:ipaddr]])
          sh("iscsiadm -m node -l -T '%s' --portal '%s'",
             [@vol[:transport_information][:iqn], @vol[:storage_node][:ipaddr]])
          # wait udev queue
          sh("/sbin/udevadm settle")
        end

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attaching,
                      :attached_at => nil,
                      :host_device_name => @os_devpath})
      end

      def detach_volume_from_host
        # iscsi logout
        sh("iscsiadm -m node -T '%s' --logout", [@vol[:transport_information][:iqn]])
        # wait udev queue
        sh("/sbin/udevadm settle")
        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:available,
                      :host_device_name=>nil,
                      :instance_id=>nil,
                      :detached_at => Time.now.utc,
                    })
        event.publish('hva/volume_detached', :args=>[@inst_id, @vol_id])
      end

      def terminate_instance
        @hv.terminate_instance(HvaContext.new(self))
      end
      

      def update_instance_state(opts, ev)
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?
        rpc.request('hva-collector', 'update_instance', @inst_id, opts)
        event.publish(ev, :args=>[@inst_id])
      end

      def update_volume_state(opts, ev)
        raise "Can't update volume info without setting @vol_id" if @vol_id.nil?
        rpc.request('sta-collector', 'update_volume', @vol_id, opts)
        event.publish(ev, :args=>[@vol_id])
      end

      # TODO: split into guessing bridge name and bridge generation parts.
      def check_interface
        vnic = @inst[:instance_nics].first
        unless vnic.nil?
          network_map = rpc.request('hva-collector', 'get_network', @inst[:instance_nics].first[:network_id])

          # physical interface
          physical_if = find_nic(@node.manifest.config.hv_ifindex)
          raise "UnknownPhysicalNIC" if physical_if.nil?

          if network_map[:vlan_id] == 0
            # bridge interface
            bridge_if = @node.manifest.config.bridge_novlan
            unless valid_nic?(bridge_if)
              sh("/usr/sbin/brctl addbr %s",    [bridge_if])
              sh("/usr/sbin/brctl setfd %s 0",    [bridge_if])
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, physical_if])
            end
          else
            # vlan interface
            vlan_if = "#{physical_if}.#{network_map[:vlan_id]}"
            unless valid_nic?(vlan_if)
              sh("/sbin/vconfig add #{physical_if} #{network_map[:vlan_id]}")
            end

            # bridge interface
            bridge_if = "#{@node.manifest.config.bridge_prefix}-#{physical_if}.#{network_map[:vlan_id]}"
            unless valid_nic?(bridge_if)
              sh("/usr/sbin/brctl addbr %s",    [bridge_if])
              sh("/usr/sbin/brctl setfd %s 0",    [bridge_if])
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, vlan_if])
            end
          end

          # interface up? down?
          [ vlan_if, bridge_if ].each do |ifname|
            if nic_state(ifname) == "down"
              sh("/sbin/ip link set %s up", [ifname])
              sh("/sbin/ip link set %s promisc on", [ifname])
            end
          end
          sleep 1
          bridge_if
        end
      end


      def get_linux_dev_path
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        @os_devpath = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_node][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]
      end

      def setup_metadata_drive
        logger.info("Setting up metadata drive image for :#{@hva_ctx.inst_id}")
        # truncate creates sparsed file.
        sh("/usr/bin/truncate -s 10m '#{@hva_ctx.metadata_img_path}'; sync;")
        # TODO: need to lock loop device not to use same device from
        # another thread/process.
        lodev=`/sbin/losetup -f`.chomp
        sh("/sbin/losetup #{lodev} '#{@hva_ctx.metadata_img_path}'")
        sh("mkfs.vfat '#{@hva_ctx.metadata_img_path}'")
        Dir.mkdir("#{@hva_ctx.inst_data_dir}/tmp") unless File.exists?("#{@hva_ctx.inst_data_dir}/tmp")
        sh("/bin/mount -t vfat #{lodev} '#{@hva_ctx.inst_data_dir}/tmp'")

        # generate metadata as file
        #File.open(File.expand_path('metadata.conf', "#{@hva_ctx.inst_data_dir}/tmp"), "w") { |f|
        #  f.puts("state=#{@inst[:state]}")
        #}

        # TODO: support for multiple interfaces.
        vnic = @inst[:instance_nics].first || {}
        # Appendix B: Metadata Categories
        # http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?AESDG-chapter-instancedata.html
        metadata_items = {
          'ami-id' => @inst[:image][:uuid],
          'ami-launch-index' => 0,
          'ami-manifest-path' => nil,
          'ancestor-ami-ids' => nil,
          'block-device-mapping/root' => '/dev/sda',
          'hostname' => @inst[:hostname],
          'instance-action' => @inst[:state],
          'instance-id' => @inst[:uuid],
          'instance-type' => @inst[:instance_spec][:uuid],
          'kernel-id' => nil,
          'local-hostname' => @inst[:hostname],
          'local-ipv4' => @inst[:ips].first,
          'mac' => vnic[:mac_addr],
          # TODO: network category support
          #'network/' => {},
          'placement/availability-zone' => nil,
          'product-codes' => nil,
          'public-hostname' => @inst[:hostname],
          'public-ipv4'    => @inst[:nat_ips].first,
          'ramdisk-id' => nil,
          'reservation-id' => nil,
          'security-groups' => @inst[:netfilter_groups].join(' '),
        }
        if @inst[:ssh_key_data]
          metadata_items.merge!({
            "public-keys/0=#{@inst[:ssh_key_data][:name]}" => @inst[:ssh_key_data][:public_key],
            'public-keys/0/openssh-key'=> @inst[:ssh_key_data][:public_key],
          })
        else
          metadata_items.merge!({'public-keys/'=>nil})
        end

        # build metadata directory tree
        metadata_base_dir = File.expand_path("meta-data", "#{@hva_ctx.inst_data_dir}/tmp")
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
            f.write(v.to_s)
          }
        }
        # user-data
        File.open(File.expand_path('user-data', "#{@hva_ctx.inst_data_dir}/tmp"), 'w') { |f|
          f.write(@inst[:user_data])
        }
        
      ensure
        # ignore any errors from cleanup work.
        sh("/bin/umount -f '#{@hva_ctx.inst_data_dir}/tmp'") rescue logger.warn($!.message)
        sh("/sbin/losetup -d #{lodev}") rescue logger.warn($!.message)
      end

      job :run_local_store, proc {
        @inst_id = request.args[0]
        logger.info("Booting #{@inst_id}")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        # create hva context
        @hva_ctx = HvaContext.new(self)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})
        # setup vm data folder
        inst_data_dir = @hva_ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)
        # copy image file
        img_src = @inst[:image][:source]
        @os_devpath = File.expand_path("#{@inst[:uuid]}", inst_data_dir)

        # vmimage cache
        vmimg_cache_dir = File.expand_path("_base", @node.manifest.config.vm_data_dir)
        FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
        vmimg_basename = File.basename(img_src[:uri])
        vmimg_cache_path = File.expand_path(vmimg_basename, vmimg_cache_dir)

        logger.debug("preparing #{@os_devpath}")

        # vmimg cached?
        unless File.exists?(vmimg_cache_path)
          logger.debug("copying #{img_src[:uri]} to #{vmimg_cache_path}")
          sh("curl --silent -o '#{vmimg_cache_path}' #{img_src[:uri]}")
        else
          md5sum = sh("md5sum #{vmimg_cache_path}")
          if md5sum[:stdout].split(' ')[0] == @inst[:image][:md5sum]
            logger.debug("verified vm cache image: #{vmimg_cache_path}")
          else
            logger.debug("not verified vm cache image: #{vmimg_cache_path}")
            sh("rm -f %s", [vmimg_cache_path])
            tmp_id = Isono::Util::gen_id
            logger.debug("copying #{img_src[:uri]} to #{vmimg_cache_path}")
            sh("curl --silent -o '#{vmimg_cache_path}.#{tmp_id}' #{img_src[:uri]}")
            sh("mv #{vmimg_cache_path}.#{tmp_id} #{vmimg_cache_path}")
            logger.debug("vmimage cache deployed on #{vmimg_cache_path}")
          end
        end

        ####
        logger.debug("copying #{vmimg_cache_path} to #{@os_devpath}")
        sh("cp -p --sparse=always %s %s",[vmimg_cache_path, @os_devpath])
        sleep 1

        setup_metadata_drive
        
        @bridge_if = check_interface
        @hv.run_instance(@hva_ctx)
        update_instance_state({:state=>:running}, 'hva/instance_started')
      }, proc {
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
      }

      job :run_vol_store, proc {
        @inst_id = request.args[0]
        @vol_id = request.args[1]
        @repository_address = request.args[2]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Booting #{@inst_id}")
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        # create hva context
        @hva_ctx = HvaContext.new(self)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})

        # setup vm data folder
        inst_data_dir = @hva_ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)

        # create volume from snapshot
        jobreq.run("sta-handle.#{@vol[:storage_node][:node_id]}", "create_volume", @vol_id, @repository_address)

        logger.debug("volume created on #{@vol[:storage_node][:node_id]}: #{@vol_id}")
        # reload volume info
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        
        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        logger.info("Attaching #{@vol_id} on #{@inst_id}")
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk
        attach_volume_to_host
        
        setup_metadata_drive
        
        # run vm
        @bridge_if = check_interface
        @hv.run_instance(@hva_ctx)
        update_instance_state({:state=>:running}, 'hva/instance_started')
        update_volume_state({:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
      }, proc {
        # TODO: Run detach & destroy volume
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
        update_volume_state({:state=>:deleted, :deleted_at=>Time.now.utc},
                              'hva/volume_deleted')
      }

      job :terminate do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        begin
          rpc.request('hva-collector', 'update_instance',  @inst_id, {:state=>:shuttingdown})

          terminate_instance

          unless @inst[:volume].nil?
            @inst[:volume].each { |volid, v|
              @vol_id = volid
              @vol = v
              # force to continue detaching volumes during termination.
              detach_volume_from_host rescue logger.error($!)
            }
          end

          # cleanup vm data folder
          FileUtils.rm_r(File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir))
        ensure
          update_instance_state({:state=>:terminated,:terminated_at=>Time.now.utc},
                                'hva/instance_terminated')
        end
      end

      # just do terminate instance and unmount volumes not to affect
      # state management.
      # called from HA at which the faluty instance get cleaned properly.
      job :cleanup do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        begin
          terminate_instance

          unless @inst[:volume].nil?
            @inst[:volume].each { |volid, v|
              @vol_id = volid
              @vol = v
              # force to continue detaching volumes during termination.
              detach_volume_from_host rescue logger.error($!)
            }
          end
        end

      end

      job :attach, proc {
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Attaching #{@vol_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'available'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk on host os
        attach_volume_to_host

        logger.info("Attaching #{@vol_id} on #{@inst_id}")

        # attach disk on guest os
        pci_devaddr=nil
        tryagain do
          pci_devaddr = @hv.attach_volume_to_guest(HvaContext.new(self))
        end

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attached,
                      :attached_at=>Time.now.utc,
                      :guest_device_name=>pci_devaddr})
        event.publish('hva/volume_attached', :args=>[@inst_id, @vol_id])
        logger.info("Attached #{@vol_id} on #{@inst_id}")
      }, proc {
        # TODO: Run detach volume
        # push back volume state to available.
        update_volume_state({:state=>:available},
                            'hva/volume_available')
        logger.error("Attach failed: #{@vol_id} on #{@inst_id}")
      }

      job :detach do
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Detaching #{@vol_id} on #{@inst_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'attached'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:detaching, :detached_at=>nil})
        # detach disk on guest os
        tryagain do
          @hv.detach_volume_from_guest(HvaContext.new(self))
        end

        # detach disk on host os
        detach_volume_from_host
      end

      job :reboot, proc {
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        # select_hypervisor :kvm, :lxc
        select_hypervisor

        # check interface
        @bridge_if = check_interface

        # reboot instance
        @hv.reboot_instance(HvaContext.new(self))
      }

      def rpc
        @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
      end

      def jobreq
        @jobreq ||= Isono::NodeModules::JobChannel.new(@node)
      end

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end

    class HvaContext

      def initialize(hvahandler)
        raise "Invalid Class: #{hvahandler}" unless hvahandler.instance_of?(HvaHandler)
        @hva = hvahandler
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
        @hva.instance_variable_get(:@os_devpath)
      end

      def metadata_img_path
        File.expand_path('metadata.img', inst_data_dir)
      end

      def bridge_if
        @hva.instance_variable_get(:@bridge_if)
      end

      def vol
        @hva.instance_variable_get(:@vol)
      end

      def inst_data_dir
        File.expand_path("#{inst_id}", node.manifest.config.vm_data_dir)
      end
    end

  end
end
