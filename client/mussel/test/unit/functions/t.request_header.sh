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
  assertEquals "$(request_header)" "-H X_VDC_ACCOUNT_UUID:${account_id}"
}

## shunit2

. ${shunit2_file}
