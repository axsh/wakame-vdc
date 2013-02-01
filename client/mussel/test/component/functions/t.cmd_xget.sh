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
  :
}

function test_cmd_xget() {
  local namespace=instance
  local cmd=xget
  local uuid=asdf
  local args="-X GET ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"

  assertEquals "$(cmd_xget ${namespace} ${cmd} ${uuid})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
