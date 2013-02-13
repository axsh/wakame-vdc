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

# in this test case the following shunit2 function should be reset.

function oneTimeSetUp() {
  :
}

function oneTimeTearDown() {
  :
}

###

function test_create_instance() {
  # :state: scheduling
  # :status: init
  instance_uuid=$(run_cmd instance create | hash_value id)
  assertEquals $? 0

  # :state: running
  # :status: init

  # :state: running
  # :status: online
  retry_until "check_document_pair instance ${instance_uuid} state running"
  assertEquals $? 0
}

function test_destroy_instance() {
  # :state: shuttingdown
  # :status: online
  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: terminated
  # :status: offline
  retry_until "check_document_pair instance ${instance_uuid} state terminated"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
