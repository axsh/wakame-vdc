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
  function task_test() { :; }
}

function test_invoke_task_no_opts() {
  invoke_task 2>/dev/null
  assertNotEquals 0 $?
}

function test_invoke_task_namespace() {
  invoke_task shunit2 2>/dev/null
  assertNotEquals 0 $?
}

function test_invoke_task_namespace_cmd() {
  invoke_task shunit2 testing 2>/dev/null
  assertNotEquals 0 $?
}

function test_invoke_task_undefined_task() {
  invoke_task shunit2 testing 2>/dev/null
  assertNotEquals 0 $?
}

function test_invoke_task_defined_task() {
  invoke_task shunit2 test
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
