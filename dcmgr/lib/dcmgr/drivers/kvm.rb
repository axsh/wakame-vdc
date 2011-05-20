module Dcmgr
  module Drivers
    class Kvm
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Rpc::KvmHelper
      include Dcmgr::Helpers::NicHelper

      def run_instance(inst, data)
        # run vm
        cmd = "kvm -m %d -smp %d -name vdc-%s -vnc :%d -drive file=%s -pidfile %s -daemonize -monitor telnet::%d,server,nowait"
        args=[inst[:instance_spec][:memory_size],
              inst[:instance_spec][:cpu_cores],
              inst[:uuid],
              inst[:runtime_config][:vnc_port],
              data[:os_devpath],
              File.expand_path('kvm.pid', data[:inst_data_dir]),
              inst[:runtime_config][:telnet_port]
             ]
        if vnic = inst[:instance_nics].first
          cmd += " -net nic,macaddr=%s -net tap,ifname=%s,script=,downscript="
          args << vnic[:mac_addr].unpack('A2'*6).join(':')
          args << vnic[:uuid]
        end
        sh(cmd, args)

        unless vnic.nil?
          node = data[:node]
          network_map = data[:network_map]

          # physical interface
          physical_if = find_nic(node.manifest.config.hv_ifindex)
          raise "UnknownPhysicalNIC" if physical_if.nil?

          if network_map[:vlan_id] == 0
            # bridge interface
            bridge_if = node.manifest.config.bridge_novlan
            unless valid_nic?(bridge_if)
              sh("/usr/sbin/brctl addbr %s",    [bridge_if])
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, physical_if])
            end
          else
            # vlan interface
            vlan_if = "#{physical_if}.#{network_map[:vlan_id]}"
            if valid_nic?(vlan_if)
              sh("/sbin/vconfig add #{physical_if} #{network_map[:vlan_id]}")
            end

            # bridge interface
            bridge_if = "#{node.manifest.config.bridge_prefix}-#{physical_if}.#{network_map[:vlan_id]}"
            if valid_nic?(bridge_if)
              sh("/usr/sbin/brctl addbr %s",    [bridge_if])
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, vlan_if])
            end
          end

          # interface up? down?
          [ vlan_if, bridge_if ].each do |ifname|
            if nic_state(ifname) == "down"
              sh("/sbin/ifconfig #{ifname} 0.0.0.0 up")
            end
          end

          sh("/sbin/ifconfig %s 0.0.0.0 up", [vnic[:uuid]])
          sh("/usr/sbin/brctl addif %s %s", [bridge_if, vnic[:uuid]])
        end

        sleep 1
      end

    end
  end
end
