#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function test_cmd_index() {
  local namespace=instance
  local cmd=index
  local args="-X GET ${DCMGR_BASE_URI}/${namespace}s.${format}?${xquery}"

  assertEquals "$(cmd_index ${namespace} ${cmd})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
