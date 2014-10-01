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

function test_instance_monitoring_enable() {
  local monitoring="enable=true"

  run_cmd instance_monitoring set_enable ${instance_uuid}
  assertEquals 0 $?
}

function test_instance_monitoring_create() {
  local enabled=true
  local title=PROCESS1
  local parmas="notification_id=mussel name=/usr/sbin/httpd"

  monitoring_uuid=$(run_cmd instance_monitoring create ${instance_uuid} | hash_value uuid)
  assertEquals 0 $?

  run_cmd instance_monitoring show ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_instance_monitoring_update() {
  local enabled=false

  run_cmd instance_monitoring update ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?

  run_cmd instance_monitoring show ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_instance_monitoring_destroy() {
  run_cmd instance_monitoring destroy ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
