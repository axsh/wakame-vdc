#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function setUp() {
  xquery=
  state=
}

function test_instance_help_stderr_to_devnull_success() {
  extract_args instance help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>/dev/null)
  assertEquals "${res}" ""
}

function test_instance_help_stderr_to_stdout_success() {
  extract_args instance help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 instance [help|index|show|create|xcreate|destroy|reboot|stop|start|poweroff|poweron]"
}

function test_instance_state() {
  extract_args instance index --state=running
  assertEquals "${state}" "running"
}

function test_instance_create() {
  extract_args instance create
  run_cmd ${MUSSEL_ARGS}
}

function test_instance_xcreate() {
  extract_args instance xcreate
  run_cmd ${MUSSEL_ARGS}
}

## shunit2

. ${shunit2_file}
