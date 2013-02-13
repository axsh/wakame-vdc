#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_single.sh

## variables

vifs_eth0_network_id=

function needs_secg() { needless_secg; }

## functions

function test_show_instance_vifs_single_null_net() {
  run_cmd ${namespace} show ${instance_uuid}
}

## shunit2

. ${shunit2_file}
