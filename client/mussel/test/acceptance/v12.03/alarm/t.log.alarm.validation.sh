#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables
params="tag=var.log.messages match_pattern=error"
alarm_actions="notification_type=dolphin notification_id=1 notification_message_type=log"

## functions

## step

function test_create_alarm_after_instance_terminated() {
  create_instance
  assertEquals 0 $?

  local resource_id=${instance_uuid}

  destroy_instance
  assertEquals 0 $?

  resource_id=${resource_id} run_cmd alarm create
  assertNotEquals 0 $?
}

## shunit2

. ${shunit2_file}
