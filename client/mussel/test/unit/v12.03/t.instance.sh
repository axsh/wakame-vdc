#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=instance

## functions

function setUp() {
  xquery=
  state=
}

### help

function test_instance_help_stderr_to_devnull_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>/dev/null)
  assertEquals "${res}" ""
}

function test_instance_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|index|show|create|xcreate|destroy|reboot|stop|start|poweroff|poweron]"
}

### index

function test_instance_index_state() {
  extract_args ${namespace} index --state=running
  assertEquals "${state}" "running"
}

### show

function test_instance_show_no_uuid() {
  extract_args ${namespace} show
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_instance_show_uuid() {
  extract_args ${namespace} show asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### create

function test_instance_create() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### xcreate

function test_instance_xcreate() {
  extract_args ${namespace} xcreate
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### backup

function test_instance_backup() {
  extract_args ${namespace} backup
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### reboot

function test_instance_reboot() {
  extract_args ${namespace} reboot
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### stop

function test_instance_stop() {
  extract_args ${namespace} stop
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### start

function test_instance_start() {
  extract_args ${namespace} start
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweroff

function test_instance_poweroff() {
  extract_args ${namespace} poweroff
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweron

function test_instance_poweron() {
  extract_args ${namespace} poweron
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
