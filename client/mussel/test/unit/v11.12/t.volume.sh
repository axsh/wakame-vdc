#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=volume

## functions

### help

function test_volume_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|attach|create|destroy|detach|index|show]"
}

### create

function test_volume_create_no_uuid() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

function test_volume_create_uuid() {
  extract_args ${namespace} create asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### attach

function test_volume_attach_no_uuid() {
  extract_args ${namespace} attach
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_volume_attach_uuid() {
  extract_args ${namespace} attach asdf qwer
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### detach

function test_volume_detach_no_uuid() {
  extract_args ${namespace} detach
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_volume_detach_uuid() {
  extract_args ${namespace} detach asdf qwer
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
