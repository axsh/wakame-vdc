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

## functions

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"","security_groups":""}}
	EOS
}

###

function test_show_instance_vifs_single_null_net() {
  run_cmd ${namespace} show ${instance_uuid}
}

## shunit2

. ${shunit2_file}
