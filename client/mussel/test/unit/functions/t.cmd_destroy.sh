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

function test_cmd_destroy() {
  local namespace=instance
  local cmd=terminate
  local uuid=asdf

  assertEquals "$(cmd_destroy ${namespace} ${cmd} ${uuid})" "call_api -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

## shunit2

. ${shunit2_file}
