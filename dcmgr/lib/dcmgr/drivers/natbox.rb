# -*- coding: utf-8 -*-
module Dcmgr
  module Drivers
    class Natbox
      include Dcmgr::Helpers::CliHelper

      def add_nat(outer_ip, inner_ip)
        # dnat
        sh("#{Dcmgr.conf.ovs_ofctl_path} add-flow #{bridge_name} '%s'" % [
           "ip",
           "priority=#{Dcmgr.conf.ovs_flow_priority}", 
           "nw_dst=#{outer_ip}",
           "actions=mod_nw_dst:#{inner_ip}",
           "normal"].join(","))

        # snat
        sh("#{Dcmgr.conf.ovs_ofctl_path} add-flow #{bridge_name} '%s'" % [
           "ip",
           "priority=#{Dcmgr.conf.ovs_flow_priority}", 
           "nw_src=#{inner_ip}",
           "actions=mod_nw_src:#{outer_ip}",
           "normal"].join(","))
      end

      def remove_nat(outer_ip, inner_ip)
        # dnat
        sh("#{Dcmgr.conf.ovs_ofctl_path} del-flows #{bridge_name} '%s'" % ["ip", "nw_dst=#{outer_ip}"].join(","))

        # snat
        sh("#{Dcmgr.conf.ovs_ofctl_path} del-flows #{bridge_name} '%s'" % ["ip", "nw_src=#{inner_ip}"].join(","))
      end

      def remove_all_nat
        sh("#{Dcmgr.conf.ovs_ofctl_path} del-flows #{bridge_name} 'ip'")
      end

      def bridge_name
        Dcmgr.conf.dc_networks[:external].bridge
      end
    end
  end
end
