#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_lifecycle.sh

## variables

## functions

function test_poweroff_instance() {
  # :state: halting
  # :status: online
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: halted
  # :status: online
  retry_until "check_document_pair instance ${instance_uuid} state halted"
  assertEquals $? 0
}

function test_poweron_instance() {
  # :state: starting
  # :status: online
  run_cmd instance poweron ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "check_document_pair instance ${instance_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
