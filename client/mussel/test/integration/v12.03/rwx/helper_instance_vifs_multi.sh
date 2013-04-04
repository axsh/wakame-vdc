#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}
vifs_eth1_network_id=${vifs_eth1_network_id:-nw-demo1}

## functions

function render_vif_table() {
  cat <<-EOS
	{
	"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"},
	"eth1":{"index":"1","network":"${vifs_eth1_network_id}","security_groups":"${security_group_uuid}"}
	}
	EOS
}
