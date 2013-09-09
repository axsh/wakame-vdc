#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=alarm

## functions

### help

function test_alarm_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd ${MUSSEL_ARGS} 2>&1)
  assertEquals "$0 ${namespace} [help|create|destroy|index|show|update|xcreate]" "${res}"
}

### create

function test_alarm_create() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### update

function test_alarm_update_no_uuid() {
  extract_args ${namespace} update
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals 0 $?
}

function test_alarm_update_uuid() {
  extract_args ${namespace} update i-demo0001
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
