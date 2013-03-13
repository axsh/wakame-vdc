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

function test_base_uri() {
  assertEquals "$(base_uri)" "$(base_uri)"
}

function test_base_uri_redefine() {
  local DCMGR_BASE_URI=asdf
  assertEquals "$(base_uri)" "$(base_uri)"
}

## shunit2

. ${shunit2_file}
