#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance
declare inst_id state

## functions

function oneTimeSetUp() {
  # required
  image_id=${image_id:-wmi-centos1d}
  hypervisor=${hypervisor:-openvz}
  cpu_cores=${cpu_cores:-1}
  memory_size=${memory_size:-256}
  vifs=
  ssh_key_id=${ssh_key_id:-ssh-demo}
}

###

function test_create_instance() {
  # :state: scheduling
  # :status: init
  inst_id=$(run_cmd ${namespace} create | hash_value id)
  assertEquals $? 0

  # :state: running
  # :status: init

  # :state: running
  # :status: online
  retry_until "check_document_pair ${namespace} ${inst_id} state running"
}

function test_stop_instance() {
  # :state: stopping
  # :status: online
  run_cmd ${namespace} stop ${inst_id} >/dev/null
  assertEquals $? 0

  # :state: stopped
  # :status: online
  retry_until "check_document_pair ${namespace} ${inst_id} state stopped"
}

function test_start_instance() {
  # :state: initializing
  # :status: online
  run_cmd ${namespace} start ${inst_id} >/dev/null
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "check_document_pair ${namespace} ${inst_id} state running"
}

function test_destroy_instance() {
  # :state: shuttingdown
  # :status: online
  run_cmd ${namespace} destroy ${inst_id} >/dev/null
  assertEquals $? 0

  # :state: terminated
  # :status: offline
  retry_until "check_document_pair ${namespace} ${inst_id} state terminated"
}

## shunit2

. ${shunit2_file}
