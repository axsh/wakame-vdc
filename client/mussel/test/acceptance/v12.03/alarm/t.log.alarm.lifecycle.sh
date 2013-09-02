#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables
params="tag=var.log.messages match_pattern=error"

## functions

### step

function test_destroy_alarm_after_instance_terminated() {
  create_instance
  assertEquals $? 0

  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals $? 0

  destroy_instance
  assertEquals $? 0

  alarm_deleted_at=$(run_cmd alarm show ${alarm_uuid} | yaml_find_first deleted_at)
  assertNotNull "alarm_deleted_at should not be null" "${alarm_deleted_at}"
}

## shunit2

. ${shunit2_file}

