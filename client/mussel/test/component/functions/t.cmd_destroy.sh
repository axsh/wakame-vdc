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
  :
}

function test_cmd_destroy() {
  local namespace=instance
  local cmd=terminate
  local uuid=asdf
  local args="-X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"

  assertEquals "$(cmd_destroy ${namespace} ${cmd} ${uuid})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
