#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

### step

function test_attach_external_ip() {
  network_id=nw-public
  ip_handle_id=$(run_cmd ip_pool acquire ${ip_pool_id} | hash_value ip_handle_id)
  assertEquals 0 $?

  network_vif_id=$(run_cmd instance show ${instance_uuid} | hash_value vif_id | head -1)
  assertEquals 0 $?

  ip_handle_id=${ip_handle_id} run_cmd network_vif attach_external_ip ${network_vif_id}
  assertEquals 0 $?

  run_cmd network_vif show_external_ip ${network_vif_id}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
