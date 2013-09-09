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

function test_cmd_put() {
  local namespace=instance
  local cmd=reboot
  local uuid=asdf

  assertEquals "$(cmd_put ${namespace} ${cmd} ${uuid})" "call_api -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### validation

function test_cmd_put_no_opts() {
  cmd_put 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_put_namespace() {
  local namespace=instance

  cmd_put ${namespace} 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_put_namespace_cmd() {
  local namespace=instance
  local cmd=reboot

  cmd_put ${namespace} ${cmd} 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_put_namespace_cmd_uuid() {
  local namespace=instance
  local cmd=reboot
  local uuid=asdf

  cmd_put ${namespace} ${cmd} ${uuid} >/dev/null
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
