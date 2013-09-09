#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function setUp() {
  function call_api() { echo call_api $*; }
}

function test_cmd_xcreate() {
  local namespace=instance
  local cmd=create

  assertEquals "$(cmd_xcreate ${namespace} ${cmd})" "call_api -X POST $(base_uri)/${namespace}s.$(suffix)"
}

### validation

function test_cmd_xcreate_no_opts() {
  cmd_xcreate 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_xcreate_namespace() {
  local namespace=instance

  cmd_xcreate ${namespace} >/dev/null
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
