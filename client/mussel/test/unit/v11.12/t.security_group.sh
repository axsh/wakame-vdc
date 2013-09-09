#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=security_group

## functions

### help

function test_security_group_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|create|destroy|index|show|update]"
}

### create

function test_security_group_create_no_uuid() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_security_group_create_uuid() {
  extract_args ${namespace} create asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### update

function test_security_group_update_no_uuid() {
  extract_args ${namespace} update
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_security_group_update_uuid() {
  extract_args ${namespace} update asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
