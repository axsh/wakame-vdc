#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ssh_key_pair

## functions

### help

function test_ssh_key_pair_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|create|destroy|index|show]"
}

### create

function test_ssh_key_pair_create_no_uuid() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_ssh_key_pair_create_uuid() {
  extract_args ${namespace} create asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
