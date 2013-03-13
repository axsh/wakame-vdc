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

function test_cmd_index() {
  local namespace=instance
  local xquery=

  assertEquals "$(cmd_index ${namespace})" "call_api -X GET $(base_uri)/${namespace}s.$(suffix)"
}

## shunit2

. ${shunit2_file}
