#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function test_run_cmd_no_opts() {
  run_cmd 2>/dev/null
  assertNotEquals $? 0
}

function test_run_cmd_opts() {
  assertEquals "$(run_cmd shunit2 testing 2>&1)" "$0 [namespace] [cmd]"
}

## shunit2

. ${shunit2_file}
