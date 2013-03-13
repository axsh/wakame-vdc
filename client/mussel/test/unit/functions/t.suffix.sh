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

function test_suffix() {
  assertEquals "$(suffix)" "$(suffix)"
}

function test_suffix_yml() {
  local DCMGR_RESPONSE_FORMAT=yml
  assertEquals "$(suffix)" "$(suffix)"
}

function test_suffix_json() {
  local DCMGR_RESPONSE_FORMAT=json
  assertEquals "$(suffix)" "$(suffix)"
}

## shunit2

. ${shunit2_file}
