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

function test_cmd_destroy() {
  local namespace=instance
  local cmd=terminate
  local uuid=asdf

  assertEquals "$(cmd_destroy ${namespace} ${cmd} ${uuid})" "call_api -X DELETE $(base_uri)/${namespace}s/${uuid}.$(suffix)"
}

### validation

function test_cmd_destroy_no_opts() {
  cmd_destroy 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_destroy_namespace() {
  local namespace=instance

  cmd_destroy ${namespace} 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_destroy_namespace_cmd() {
  local namespace=instance
  local cmd=show

  cmd_destroy ${namespace} ${cmd} 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
