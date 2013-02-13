#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_multi.sh

## variables

function needs_secg() { true; }

## functions

###

function test_show_instance_vifs_multi_networking() {
  run_cmd ${namespace} show ${instance_uuid}
}

## shunit2

. ${shunit2_file}
