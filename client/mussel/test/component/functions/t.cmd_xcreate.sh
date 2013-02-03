#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function test_cmd_xcreate() {
  local namespace=instance
  local cmd=terminate
  local MUSSEL_CUSTOM_DATA=
  local args="-X POST ${base_uri}/${namespace}s.${format}"

  assertEquals "$(cmd_xcreate ${namespace})" "curl ${args}"
}

function test_cmd_xcreate_custom_data() {
  local namespace=instance
  local cmd=terminate
  local MUSSEL_CUSTOM_DATA="a=b"
  local args="-X POST ${MUSSEL_CUSTOM_DATA} ${base_uri}/${namespace}s.${format}"

  assertEquals "$(cmd_xcreate ${namespace})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
