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

function test_cmd_xcreate() {
  local namespace=instance
  local cmd=create

  assertEquals "$(cmd_xcreate ${namespace} ${cmd})" "call_api -X POST ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
