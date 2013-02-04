#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function test_call_api_curl_opts() {
  local args="-X GET ${DCMGR_BASE_URI}/instance/show"

  assertEquals "$(call_api ${args})" "curl ${args}"
}

## shunit2

. ${shunit2_file}
