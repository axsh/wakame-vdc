#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_ipaddr=

function needs_vif() { true; }
function needs_secg() { true; }

image_id=${image_id:-wmi-centos1d}
vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

## functions

### instance

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	EOS
}

### shunit2 setup
