#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function setUp() {
  cleanup_vm
}

function tearDown() {
  cleanup_vm
}

function test_build_vm() {
  ${builder_path} ${suite_path}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
