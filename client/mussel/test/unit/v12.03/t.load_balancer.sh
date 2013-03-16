#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=load_balancer

## functions

function setUp() {
  xquery=
  state=
}

### help

function test_load_balancer_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|create|destroy|index|poweroff|poweron|register|show|unregister|update|xcreate]"
}

### index

function test_load_balancer_index_state() {
  extract_args ${namespace} index --state=running
  assertEquals "${state}" "running"
}

### create

function test_load_balancer_create() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
}

### poweroff

function test_load_balancer_poweroff_no_uuid() {
  extract_args ${namespace} poweroff
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_load_balancer_poweroff_uuid() {
  extract_args ${namespace} poweroff i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### poweron

function test_load_balancer_poweron_no_uuid() {
  extract_args ${namespace} poweron
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_load_balancer_poweron_uuid() {
  extract_args ${namespace} poweron i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### register

function test_load_balancer_register_no_uuid() {
  extract_args ${namespace} register
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_load_balancer_register_uuid() {
  extract_args ${namespace} register i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### unregister

function test_load_balancer_unregister_no_uuid() {
  extract_args ${namespace} unregister
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_load_balancer_unregister_uuid() {
  extract_args ${namespace} unregister i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### update

function test_load_balancer_update_no_uuid() {
  extract_args ${namespace} update
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_load_balancer_update_uuid() {
  extract_args ${namespace} update i-xxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
