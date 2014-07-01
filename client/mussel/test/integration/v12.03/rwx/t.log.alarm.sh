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
alarm_actions="notification_type=dolphin notification_id=1 notification_message_type=log"

## functions

function test_create_alarm() {
  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals 0 $?
}

function test_update_alarm_not_support_alarm_id() {
  local enabled=false
  run_cmd alarm update vol-demo0001 >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm_not_found_alarm_id() {
  local enabled=false
  run_cmd alarm update alm-demo0001 >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm_zero_notification_periods() {
  notification_periods=0 run_cmd alarm update ${alarm_uuid} >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm_not_match_pattern() {
  params="tag=var.log.httpd.access_log match_pattern=""" run_cmd alarm update ${alarm_uuid}
  assertNotEquals 0 $?
}

function test_update_alarm_not_support_notification_type() {
  alarm_actions="notification_type=log notification_id=1 notification_message_type=log" run_cmd alarm update ${alarm_uuid} >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm_not_notification_type() {
  alarm_actions="notification_id=1 notification_message_type=log" run_cmd alarm update ${alarm_uuid} >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm_not_notification_id() {
  alarm_actions="notification_type=dolphin notification_message_type=log" run_cmd alarm update ${alarm_uuid} >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm_not_notification_message_type() {
  alarm_actions="notification_type=dolphin notification_id=1" run_cmd alarm update ${alarm_uuid} >/dev/null
  assertNotEquals 0 $?
}

function test_update_alarm() {
  local enabled=false
  local notification_periods=90
  local params="tag=var.log.httpd.access_log match_pattern=access"
  local alarm_actions="notification_type=dolphin notification_id=2 notification_message_type=log"
  enabled=${enabled} notification_periods=${notification_periods} params=${params} alarm_actions=${alarm_actions} run_cmd alarm update ${alarm_uuid} >/dev/null
  assertEquals 0 $?
}

function test_destroy_alarm() {
  run_cmd alarm destroy  ${alarm_uuid} >/dev/null
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}