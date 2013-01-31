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

function test_cmd_xget() {
  local namespace=instance
  local cmd=show
  local uuid=asdf

  assertEquals "$(cmd_xget ${namespace} ${cmd} ${uuid})" "call_api -X GET ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

## shunit2

. ${shunit2_file}
