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
  function cmd_index() { echo cmd_index $*; }
}

function test_cmd_default() {
  assertEquals \
   "$(cmd_default namespace)" "cmd_index namespace"
}

### validation

function test_cmd_default_no_opts() {
  cmd_default 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_default_namespace() {
  local namespace=instance

  cmd_default ${namespace} >/dev/null
  assertEquals $? 0
}

function test_cmd_default_namespace_cmd() {
  local namespace=instance
  local cmd=show

  cmd_default ${namespace} ${cmd} 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
