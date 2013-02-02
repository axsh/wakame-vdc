#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=load_balancer

## functions

function setUp() {
  xquery=
  state=
}

### help

function test_load_balancer_help_stderr_to_devnull_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>/dev/null)
  assertEquals "${res}" ""
}

function test_load_balancer_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|create|destroy|index|poweroff|poweron|show|xcreate]"
}

### index

function test_load_balancer_index_state() {
  extract_args ${namespace} index --state=running
  assertEquals "${state}" "running"
}

### show

function test_load_balancer_show_no_uuid() {
  extract_args ${namespace} show
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_load_balancer_show_uuid() {
  extract_args ${namespace} show asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### destroy

function test_load_balancer_destroy() {
  extract_args ${namespace} destroy asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### create

function test_load_balancer_create() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
}

### xcreate

function test_load_balancer_xcreate() {
  extract_args ${namespace} xcreate
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweroff

function test_load_balancer_poweroff() {
  extract_args ${namespace} poweroff i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweron

function test_load_balancer_poweron() {
  extract_args ${namespace} poweron i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
