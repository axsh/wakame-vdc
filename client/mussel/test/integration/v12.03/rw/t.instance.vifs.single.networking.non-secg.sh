#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs.sh

## variables

function needs_secg() { needless_secg; }

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

## functions

###

function test_show_instance_vifs_single_networking() {
  run_cmd ${namespace} show ${instance_uuid}
}

## shunit2

. ${shunit2_file}
