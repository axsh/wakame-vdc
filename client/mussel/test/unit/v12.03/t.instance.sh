#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance

## functions

function setUp() {
  xquery=
  state=
}

### help

function test_instance_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|backup|create|destroy|index|poweroff|poweron|reboot|show|start|stop|xcreate]"
}

### index

function test_instance_index_state() {
  extract_args ${namespace} index --state=running
  assertEquals "${state}" "running"
}

### create

function test_instance_create() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### backup

function test_instance_backup_no_uuid() {
  extract_args ${namespace} backup
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_backup_uuid() {
  extract_args ${namespace} backup i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### reboot

function test_instance_reboot_no_uuid() {
  extract_args ${namespace} reboot
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_reboot_uuid() {
  extract_args ${namespace} reboot i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### stop

function test_instance_stop_no_uuid() {
  extract_args ${namespace} stop
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_stop_uuid() {
  extract_args ${namespace} stop i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### start

function test_instance_start_no_uuid() {
  extract_args ${namespace} start
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_start_uuid() {
  extract_args ${namespace} start i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweroff

function test_instance_poweroff_no_uuid() {
  extract_args ${namespace} poweroff
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_poweroff_uuid() {
  extract_args ${namespace} poweroff i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweron

function test_instance_poweron_no_uuid() {
  extract_args ${namespace} poweron
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_poweron_uuid() {
  extract_args ${namespace} poweron i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
