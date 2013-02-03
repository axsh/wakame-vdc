#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=network

## functions

### help

function test_network_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|add_pool|create|del_pool|destroy|get_pool|index|release|reserve|show]"
}

### create

function test_network_create_no_opts() {
  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_network_create_opts() {
  local gw=192.0.2.1
  local network=192.0.2.0
  local prefix=24
  local description=example

  extract_args ${namespace} create
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### reserve

function test_network_reserve_no_opts() {
  extract_args ${namespace} reserve
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_network_reserve_opts() {
  extract_args ${namespace} reserve asdf 192.0.2.2
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## release

function test_network_release_no_opts() {
  extract_args ${namespace} release
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_network_release_opts() {
  extract_args ${namespace} release asdf 192.0.2.2
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## add_pool

function test_network_add_pool_no_opts() {
  extract_args ${namespace} add_pool
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_network_add_pool_opts() {
  extract_args ${namespace} add_pool asdf 192.0.2.2
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## del_pool

function test_network_del_pool_no_opts() {
  extract_args ${namespace} del_pool
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_network_del_pool_opts() {
  extract_args ${namespace} del_pool asdf 192.0.2.2
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## get_pool

function test_network_get_pool() {
  extract_args ${namespace} get_pool
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
