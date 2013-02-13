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

###

function test_poweroff_instance() {
  # :state: halting
  # :status: online
  run_cmd ${namespace} poweroff ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: halted
  # :status: online
  retry_until "check_document_pair ${namespace} ${instance_uuid} state halted"
  assertEquals $? 0
}

function test_poweron_instance() {
  # :state: starting
  # :status: online
  run_cmd ${namespace} poweron ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "check_document_pair ${namespace} ${instance_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
