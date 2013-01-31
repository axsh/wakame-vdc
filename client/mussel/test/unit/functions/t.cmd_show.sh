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
}

function test_cmd_show() {
  local namespace=instance
  local xquery=
  local uuid=asdf

  assertEquals "$(cmd_show ${namespace} show ${uuid})" "call_api -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

## shunit2

. ${shunit2_file}
