#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=undefined

## functions

function setUp() {
  :
}

### help

function test_undefined_help() {
  extract_args ${namespace} help
  run_cmd  ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
