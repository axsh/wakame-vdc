#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_multi.sh

## variables

function needs_vif() { true; }
function needs_secg() { needless_secg; }

## functions

###

function test_show_instance_vifs_multi_networking() {
  run_cmd instance show ${instance_uuid}
}

## shunit2

. ${shunit2_file}
