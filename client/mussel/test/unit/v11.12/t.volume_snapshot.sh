#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=volume_snapshot

## functions

function setUp() {
  :
}

### help

function test_volume_snapshot_help_stderr_to_devnull_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>/dev/null)
  assertEquals "${res}" ""
}

function test_volume_snapshot_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|destroy|index|show]"
}

### index

function test_volume_snapshot_index() {
  extract_args ${namespace} index
  assertEquals $? 0
}

### show

function test_volume_snapshot_show_no_uuid() {
  extract_args ${namespace} show
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_volume_snapshot_show_uuid() {
  extract_args ${namespace} show asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
