#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ip_handle

## functions

function setUp() {
  :
}

function tearDown() {
  :
}

### create

function test_ip_handle_expire_at() {
  local cmd=expire_at
  local uuid=shunit2
  local time_to=1398057989
  local opts="
    --time-to=${time_to}
  "
  local params="
    time_to=${time_to}
  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/expire_at.$(suffix)"
}

. ${shunit2_file}
