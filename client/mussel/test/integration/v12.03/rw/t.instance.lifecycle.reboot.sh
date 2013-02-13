#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance
declare instance_uuid state

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
  instance_uuid=$(run_cmd ${namespace} create | hash_value id)
  assertEquals $? 0

  # :state: running
  # :status: init

  # :state: running
  # :status: online
  retry_until "check_document_pair ${namespace} ${instance_uuid} state running"
}

function test_reboot_instance() {
  # :state: running
  # :status: online
  run_cmd ${namespace} reboot ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "check_document_pair ${namespace} ${instance_uuid} status online"
}

function test_destroy_instance() {
  # :state: shuttingdown
  # :status: online
  run_cmd ${namespace} destroy ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: terminated
  # :status: offline
  retry_until "check_document_pair ${namespace} ${instance_uuid} state terminated"
}

## shunit2

. ${shunit2_file}
