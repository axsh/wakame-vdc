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

### opts

function test_request_header() {
  assertEquals "-H X_VDC_ACCOUNT_UUID:${account_id}" "$(request_header)"
}

function test_request_header_empty_id() {
  assertEquals "" "$(account_id= request_header)"
}

## shunit2

. ${shunit2_file}
