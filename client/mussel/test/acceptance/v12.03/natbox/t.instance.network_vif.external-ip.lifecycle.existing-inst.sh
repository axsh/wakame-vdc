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
ip_handle_id=${ip_handle_id} # ip-xxx
instance_uuid=${instance_uuid:-}

## functions

function oneTimeSetUp() {
  :
}

function oneTimeTearDown() {
  :
}

### step

function test_get_single_ip_pool() {
  [[ -n "${ip_pool_id}"   ]] || { echo "[WARN] test skipped"; return 0; }

  run_cmd ip_pool ip_handles ${ip_pool_id}
  assertEquals 0 $?
}

function test_get_single_ip_handle() {
  [[ -n "${ip_handle_id}"   ]] || { echo "[WARN] test skipped"; return 0; }

  run_cmd ip_handle show ${ip_handle_id}
  assertEquals 0 $?
}

function test_get_instance_network_vif() {
  [[ -n "${instance_uuid}" ]] || { echo "[WARN] test skipped"; return 0; }

  network_vif_id=$(run_cmd instance show ${instance_uuid} | hash_value vif_id | head -1)
  [[ -n "${network_vif_id}" ]]
  assertEquals 0 $?
}

function test_attach_external_ip_to_network_vif() {
  [[ -n "${network_vif_id}" ]] || { echo "[WARN] test skipped"; return 0; }
  [[ -n "${ip_handle_id}"   ]] || { echo "[WARN] test skipped"; return 0; }

  ip_handle_id=${ip_handle_id} run_cmd network_vif attach_external_ip ${network_vif_id}
  assertEquals 0 $?

  run_cmd network_vif show_external_ip ${network_vif_id}
  assertEquals 0 $?
}

function test_detach_external_ip_from_network_vif() {
  [[ -n "${network_vif_id}" ]] || { echo "[WARN] test skipped"; return 0; }
  [[ -n "${ip_handle_id}"   ]] || { echo "[WARN] test skipped"; return 0; }

  ip_handle_id=${ip_handle_id} run_cmd network_vif detach_external_ip ${network_vif_id}
  assertEquals 0 $?

  run_cmd network_vif show_external_ip ${network_vif_id}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
