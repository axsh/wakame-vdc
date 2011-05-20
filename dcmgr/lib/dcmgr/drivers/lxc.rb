module Dcmgr
  module Drivers
    class Lxc
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_config(inst, inst_data_dir)
        # create config file i-xxxxxxxx.log
        inst_id = inst[:uuid]
        vnic = inst[:instance_nics].first
        mac_addr = vnic[:mac_addr].unpack('A2'*6).join(':')

        config_name = "#{inst_data_dir}/config.#{inst_id}"
        config = File.open(config_name, 'w')
        config.puts "lxc.utsname = #{inst_id}"
        config.puts "lxc.tty = 4"
        config.puts "lxc.network.type = veth"
        config.puts "lxc.network.flags = up"
        config.puts "lxc.network.link = br0"
        config.puts "lxc.network.name = eth0"
        config.puts "lxc.network.mtu = 1500"
        config.puts "lxc.network.hwaddr = #{mac_addr}"
        config.puts "lxc.network.ipv4 = 0.0.0.0"
        config.puts "lxc.rootfs = #{inst_data_dir}/rootfs"
        config.puts "lxc.cgroup.devices.deny = a"
        config.puts "lxc.cgroup.devices.allow = c 1:3 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:5 rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:1 rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:0 rwm"
        config.puts "lxc.cgroup.devices.allow = c 4:0 rwm"
        config.puts "lxc.cgroup.devices.allow = c 4:1 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:9 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:8 rwm"
        config.puts "lxc.cgroup.devices.allow = c 136:* rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:2 rwm"
        config.puts "lxc.cgroup.devices.allow = c 254:0 rwm"
        config.close
        config_name
      end

      def run_instance(inst, data)
        # run lxc
        os_devpath = data[:os_devpath]
        inst_data_dir = data[:inst_data_dir]

        sh("mkdir #{inst_data_dir}/rootfs")
        cmd = "mount %s %s/rootfs"
        args = [os_devpath, inst_data_dir]
        if inst[:image][:boot_dev_type] == 2
          cmd += " -o loop"
        end
        sh(cmd, args)

        config_name = create_config(inst, inst_data_dir)

        sh("lxc-create -f %s -n %s", [config_name, inst[:uuid]])
        sh("lxc-start -n %s -l DEBUG -o %s/%s.log -d", [inst[:uuid], inst_data_dir, inst[:uuid]])
      end

      def terminate_instance(inst_id, inst_data_dir)
        sh("lxc-stop -n #{inst_id}")
        sh("lxc-destroy -n #{inst_id}")
        sh("umount #{inst_data_dir}/rootfs")
      end

      def attach_volume_to_guest(inst, linux_dev_path)
        sddev = File.expand_path(File.readlink(linux_dev_path), '/dev/disk/by-path')
        ls_la = `ls -la #{sddev}`
        if ls_la =~ /brw-rw---- [0-9] root disk ([0-9]+), ([0-9]+) [0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+ #{sddev}/m
          devnum = [$1, $2].join(":")
        else
        end
        sh("echo \"b #{devnum} rwm\" > /cgroup/#{inst[:uuid]}/devices.allow")
        devnum
      end

      def detach_volume_from_guest(vol, inst)
        devnum = vol[:guest_device_name]
        sh("echo \"b #{devnum} rwm\" > /cgroup/#{inst[:uuid]}/devices.deny")
      end

    end
  end
end
