#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function setUp() {
  function call_api() { echo call_api $*; }
}

function test_cmd_index() {
  local namespace=instance
  local xquery=

  assertEquals "$(cmd_index ${namespace})" "call_api -X GET ${base_uri}/${namespace}s.${format}?"
}

## shunit2

. ${shunit2_file}
