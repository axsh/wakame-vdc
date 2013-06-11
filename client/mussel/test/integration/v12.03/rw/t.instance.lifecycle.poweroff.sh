#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

function oneTimeSetUp() {
  create_ssh_key_pair
}

function oneTimeTearDown() {
  destroy_ssh_key_pair
}

###

function test_destroy_poweroff_instance() {

  # :state: scheduling
  # :status: init
  instance_uuid=$(run_cmd instance create | hash_value id)
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals $? 0

  # :state: halting
  # :status: online
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: halted
  # :status: online
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals $? 0

  # :state: shuttingdown
  # :status: online
  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: terminated
  # :status: offline
  retry_until "document_pair? instance ${instance_uuid} state terminated"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
