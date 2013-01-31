#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function setUp() {
  function call_api() { echo call_api $*; }
  function cmd_index() { echo cmd_index $*; }
}

function test_cmd_default() {
  assertEquals \
   "$(cmd_default namespace)" "cmd_index namespace"
}

## shunit2

. ${shunit2_file}
