#!/bin/bash

set -e

# prepare configuration files

# dcmgr
(
  cd ${VDC_ROOT}/dcmgr/config/
  cp -f dcmgr.conf.example dcmgr.conf
  cp -f snapshot_repository.yml.example snapshot_repository.yml
#cp -f hva.conf.example hva.conf
  cp -f nsa.conf.example nsa.conf
  cp -f sta.conf.example sta.conf
  
# dcmgr:hva
  cat <<EOS > hva.conf
#------------------------
# Configuration file for hva.
#------------------------

# directory to store VM local data.
config.vm_data_dir = "${VDC_ROOT}/tmp/instances"

# Decides what kind of edge networking will be used. If omitted, the default 'netfilter' option will be used
# * 'netfilter'
# * 'legacy_netfilter' #no longer supported, has issues with multiple vnic vm isolation
# * 'openflow' #experimental, requires additional setup
# * 'off'
config.edge_networking = 'netfilter'

# netfilter and openflow
config.enable_ebtables = true
config.enable_iptables = true
config.enable_subnet = false
config.enable_gre = true

# display netfitler commands
config.verbose_netfilter = false
config.verbose_openflow  = false

# netfilter log output flag
config.packet_drop_log = false

# debug netfilter
config.debug_iptables = false

# Use ipset for netfilter
config.use_ipset       = false

# Directory used by Open vSwitch daemon for run files
config.ovs_run_dir = '${VDC_ROOT}/ovs/var/run/openvswitch'

# Path for ovs-ofctl
config.ovs_ofctl_path = '${VDC_ROOT}/ovs/bin/ovs-ofctl'

# Trema base directory
config.trema_dir = '${VDC_ROOT}/trema'
config.trema_tmp = '${VDC_ROOT}/tmp/trema'

dc_network("public") {
  bridge_type "linux"
  interface "eth0"
  bridge "br0"
}
EOS
)
