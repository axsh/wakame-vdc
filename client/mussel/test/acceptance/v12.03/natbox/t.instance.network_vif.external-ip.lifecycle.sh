#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

#ssh_user=${ssh_user:-root}
ip_handle_id=

## functions

### step

function test_acquire_ip_pool() {
  ip_handle_id=$(network_id=${vifs_eth0_network_id} run_cmd ip_pool acquire ${ip_pool_id} | hash_value ip_handle_id)
  [[ -n "${ip_handle_id}" ]]
  assertEquals 0 $?
}

function test_get_instance_network_vif() {
  network_vif_id=$(run_cmd instance show ${instance_uuid} | hash_value vif_id | head -1)
  [[ -n "${network_vif_id}" ]]
  assertEquals 0 $?
}

function test_attach_external_ip() {
  ip_handle_id=${ip_handle_id} run_cmd network_vif attach_external_ip ${network_vif_id}
  assertEquals 0 $?

  run_cmd network_vif show_external_ip ${network_vif_id}
  assertEquals 0 $?
}

function test_detach_external_ip() {
  ip_handle_id=${ip_handle_id} run_cmd network_vif detach_external_ip ${network_vif_id}
  assertEquals 0 $?

  run_cmd network_vif show_external_ip ${network_vif_id}
  assertEquals 0 $?
}

function test_release_ip_pool() {
  ip_handle_id=${ip_handle_id} run_cmd ip_pool release ${ip_pool_id}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
