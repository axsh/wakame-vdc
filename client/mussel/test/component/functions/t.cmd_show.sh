#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function test_cmd_show() {
  local namespace=instance
  local cmd=show
  local uuid=asdf
  local args="-X GET ${base_uri}/${namespace}s/${uuid}.${format}"

  assertEquals "$(cmd_show ${namespace} ${cmd} ${uuid})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
