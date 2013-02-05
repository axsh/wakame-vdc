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

function test_cmd_xget() {
  local namespace=instance
  local cmd=show
  local uuid=asdf

  assertEquals "$(cmd_xget ${namespace} ${cmd} ${uuid})" "call_api -X GET ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${DCMGR_RESPONSE_FORMAT}"
}

### validation

function test_cmd_xget_no_opts() {
  cmd_xget 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_xget_namespace() {
  local namespace=instance

  cmd_xget ${namespace} 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_xget_namespace_cmd() {
  local namespace=instance
  local cmd=show

  cmd_xget ${namespace} ${cmd} 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
