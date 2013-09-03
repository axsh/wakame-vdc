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

###

function test_create_alarm_not_resource_id() {
  resource_id= run_cmd alarm create
  assertNotEquals $? 0
}

function test_create_alarm_not_metric_name() {
  resource_id=${instance_uuid} metric_name= run_cmd alarm create
  assertNotEquals $? 0
}

function test_create_alarm_not_params() {
  resource_id=${instance_uuid} params= run_cmd alarm create
  assertNotEquals $? 0
}

function test_create_alarm_not_notification_periods() {
  resource_id=${instance_uuid} notification_periods= run_cmd alarm create
  assertNotEquals $? 0
}

function test_create_alarm() {
  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals $? 0
}

function test_destroy_alarm() {
  run_cmd alarm destroy  ${alarm_uuid} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}