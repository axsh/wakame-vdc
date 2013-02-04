#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function test_cmd_xget() {
  local namespace=instance
  local cmd=xget
  local uuid=asdf
  local args="-X GET ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"

  assertEquals "$(cmd_xget ${namespace} ${cmd} ${uuid})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
