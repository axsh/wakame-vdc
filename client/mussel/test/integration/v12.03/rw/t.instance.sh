#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})
declare inst_id state

## functions

function oneTimeSetUp() {
  # required
  image_id=${image_id:-wmi-centos1d}
  hypervisor=${hypervisor:-openvz}
  cpu_cores=${cpu_cores:-1}
  memory_size=${memory_size:-256}
  vifs=${vifs:-'{}'}
  ssh_key_id=${ssh_key_id:-ssh-demo}
}

###

function test_create_instance() {
  inst_id=$(run_cmd ${namespace} create | hash_value id)
  assertEquals $? 0
}

function test_wait_for_instance_state_is_running() {
  retry_until "check_document_pair ${namespace} ${inst_id} state running"
}

function test_reboot_instance() {
  run_cmd ${namespace} reboot ${inst_id} >/dev/null
  assertEquals $? 0
}

function test_wait_for_instance_status_is_online() {
  retry_until "check_document_pair ${namespace} ${inst_id} status online"
}

function test_destroy_instance() {
  run_cmd ${namespace} destroy ${inst_id} >/dev/null
  assertEquals $? 0
}

function test_wait_for_instance_state_is_terminated() {
  retry_until "check_document_pair ${namespace} ${inst_id} state terminated"
}

## shunit2

. ${shunit2_file}
