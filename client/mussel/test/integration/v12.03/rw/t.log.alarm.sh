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

###

function test_create_alarm_not_resource_id() {
  resource_id= run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_support_resource_id() {
  resource_id=vol-demo001 run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_found_resource_id() {
  run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_metric_name() {
  resource_id=${instance_uuid} metric_name= run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_params() {
  resource_id=${instance_uuid} params= run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_notification_periods() {
  resource_id=${instance_uuid} notification_periods= run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_zero_notification_periods() {
  resource_id=${instance_uuid} notification_periods=0 run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_match_pattern() {
  resource_id=${instance_uuid} params="tag=var.log.messages" run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_support_tag() {
  resource_id=${instance_uuid} params="tag=var-log-messages match_pattern=error" run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_support_notification_type() {
  resource_id=${instance_uuid} alarm_actions="notification_type=log notification_id=1 notification_message_type=log" run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_notification_type() {
  resource_id=${instance_uuid} alarm_actions="notification_id=1 notification_message_type=log" run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_notification_id() {
  resource_id=${instance_uuid} alarm_actions="notification_type=dolphin notification_message_type=log" run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm_not_notification_message_type() {
  resource_id=${instance_uuid} alarm_actions="notification_type=dolphin notification_id=1" run_cmd alarm create
  assertNotEquals 0 $?
}

function test_create_alarm() {
  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals 0 $?
}

function test_destroy_alarm_not_support_resource_id() {
  run_cmd alarm destroy ${instance_uuid} >/dev/null
  assertNotEquals 0 $?
}

function test_destroy_alarm_not_found_resource_id() {
  run_cmd alarm destroy alm-demo0001 >/dev/null
  assertNotEquals 0 $?
}

function test_destroy_alarm() {
  run_cmd alarm destroy ${alarm_uuid} >/dev/null
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
