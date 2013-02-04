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
  function call_api() { echo call_api $*; }
}

function test_cmd_show() {
  local namespace=instance
  local xquery=
  local uuid=asdf

  assertEquals "$(cmd_show ${namespace} show ${uuid})" "call_api -X GET ${DCMGR_BASE_URI}/${namespace}s/${uuid}.${format}"
}

### validation

function test_cmd_show_no_opts() {
  cmd_show 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_show_namespace() {
  local namespace=instance

  cmd_show ${namespace} 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_show_namespace_cmd() {
  local namespace=instance
  local cmd=show

  cmd_show ${namespace} ${cmd} 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
