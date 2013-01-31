#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function test_cmd_help() {
  assertEquals \
   "$(cmd_help command sub-commands 2>&1)" \
          "$0 command [help|sub-commands]"
}

### validation

function test_cmd_help_no_opts() {
  cmd_help 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_help_namespace() {
  local namespace=instance

  cmd_help ${namespace} 2>/dev/null
  assertNotEquals $? 0
}

function test_cmd_help_namespace_cmd() {
  local namespace=instance
  local cmd=show

  cmd_help ${namespace} ${cmd} 2>/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
