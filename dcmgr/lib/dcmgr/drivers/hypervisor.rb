module Dcmgr
  module Drivers
    class Hypervisor

      def run_instance(hc)
      end

      def terminate_instance(hc)
      end

      def reboot_instance(hc)
      end
      
      def check_interface(hc)
        hc.inst[:instance_nics].each { |vnic|
          next if vnic[:network_port].nil?

          network = hc.rpc.request('hva-collector', 'get_network', vnic[:network_id])
          
          fwd_if = phy_if = network[:physical_network][:interface]
          bridge_if = network[:link_interface]
          
          if network[:vlan_id].to_i > 0 && phy_if
            fwd_if = "#{phy_if}.#{network[:vlan_id]}"
            unless valid_nic?(vlan_if)
              sh("/sbin/vconfig add #{phy_if} #{network[:vlan_id]}")
              sh("/sbin/ip link set %s up", [fwd_if])
              sh("/sbin/ip link set %s promisc on", [fwd_if])
            end
          end

          unless valid_nic?(bridge_if)
            sh("/usr/sbin/brctl addbr %s",    [bridge_if])
            sh("/usr/sbin/brctl setfd %s 0",    [bridge_if])
            # There is null case for the forward interface to create closed bridge network.
            if fwd_if
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, fwd_if])
            end
          end
        }
        sleep 1
      end
      
      def setup_metadata_drive(hc,metadata_items)
        begin
          inst_data_dir = hc.inst_data_dir
          FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)
          
          logger.info("Setting up metadata drive image for :#{hc.inst_id}")
          # truncate creates sparsed file.
          sh("/usr/bin/truncate -s 10m '#{hc.metadata_img_path}'; sync;")
          # TODO: need to lock loop device not to use same device from
          # another thread/process.
          lodev=`/sbin/losetup -f`.chomp
          sh("/sbin/losetup #{lodev} '#{hc.metadata_img_path}'")
          sh("mkfs.vfat -n METADATA '#{hc.metadata_img_path}'")
          Dir.mkdir("#{hc.inst_data_dir}/tmp") unless File.exists?("#{hc.inst_data_dir}/tmp")
          sh("/bin/mount -t vfat #{lodev} '#{hc.inst_data_dir}/tmp'")
          
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
          # ignore any errors from cleanup work.
          sh("/bin/umount -f '#{hc.inst_data_dir}/tmp'") rescue logger.warn($!.message)
          sh("/sbin/losetup -d #{lodev}") rescue logger.warn($!.message)
        end
      end

      def attach_volume_to_guest(hc)
      end

      def detach_volume_from_guest(hc)
      end

      def self.select_hypervisor(hypervisor)
        case hypervisor
        when "kvm"
          hv = Dcmgr::Drivers::Kvm.new
        when "lxc"
          hv = Dcmgr::Drivers::Lxc.new
        when "esxi"
          hv = Dcmgr::Drivers::ESXi.new
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
        hv
      end
    end
  end
end
