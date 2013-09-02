#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
params="tag=var.log.messages match_pattern=error"

## functions

function test_create_alarm() {
  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals $? 0
}

function test_update_alarm() {
  local enabled=0
  local notification_periods=180
  local params="tag=var.log.httpd.access_log match_pattern=access"
  enabled=${enabled} notification_periods=${notification_periods} params=${params} run_cmd alarm update ${alarm_uuid} >/dev/null
  assertEquals $? 0
}

function test_destroy_alarm() {
  run_cmd alarm destroy  ${alarm_uuid} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}