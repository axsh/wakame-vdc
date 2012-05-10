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
vm_data_dir "${VDC_ROOT}/tmp/instances"

# Decides what kind of edge networking will be used. If omitted, the default 'netfilter' option will be used
# * 'netfilter'
# * 'legacy_netfilter' #no longer supported, has issues with multiple vnic vm isolation
# * 'openflow' #experimental, requires additional setup
# * 'off'
edge_networking 'netfilter'

# netfilter and openflow
enable_ebtables true
enable_iptables true
enable_subnet false
enable_gre true

# physical nic index
hv_ifindex      2 # ex. /sys/class/net/eth0/ifindex => 2

# bridge device name novlan
bridge_novlan   'br0'

# display netfitler commands
verbose_netfilter false
verbose_openflow  false

# netfilter log output flag
packet_drop_log false

# debug netfilter
debug_iptables false

# Use ipset for netfilter
use_ipset       false

# Directory used by Open vSwitch daemon for run files
ovs_run_dir '${VDC_ROOT}/ovs/var/run/openvswitch'

# Path for ovs-ofctl
ovs_ofctl_path '${VDC_ROOT}/ovs/bin/ovs-ofctl'

# Trema base directory
trema_dir '${VDC_ROOT}/trema'
trema_tmp '${VDC_ROOT}/tmp/trema'

dc_network("public") {
  bridge_type "linux"
  interface "eth0"
  bridge "br0"
}

dc_network("null1") {
  bridge_type "linux"
  interface "eth0"
  bridge "br0"
}

dc_network("null2") {
  bridge_type "linux"
  interface "eth0"
  bridge "br0"
}
EOS
)
