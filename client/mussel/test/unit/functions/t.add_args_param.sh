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

###

function test_add_args_param_no_opts() {
  add_args_param >/dev/null 2>&1
  assertNotEquals 0 $?
}

function test_add_args_param_empty_value() {
  local name_args=""
  assertEquals "" "$(add_args_param name)"
}

function test_add_args_param_defined_value() {
  local name_args="foo bar"
  assertEquals "--data-urlencode 'foo'
--data-urlencode 'bar'" "$(add_args_param name)"
}

## shunit2

. ${shunit2_file}
