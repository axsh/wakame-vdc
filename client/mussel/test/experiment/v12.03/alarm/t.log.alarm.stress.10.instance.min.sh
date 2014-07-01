#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_alarm.sh

## variables
params=${params:-"tag=var.log.httpd.access_log match_pattern=error"}

## functions
function test_create_alarms() {
  for r in ${resource_ids}; do
    local resource_id=${r}
    alarm_uuid=$(run_cmd alarm create | hash_value uuid)
    assertEquals 0 $?

    display_name=${alarm_uuid} run_cmd alarm update ${alarm_uuid}
    assertEquals 0 $?
  done
}

## shunit2

. ${shunit2_file}