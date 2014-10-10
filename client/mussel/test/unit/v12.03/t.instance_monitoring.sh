#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance_monitoring

## functions

### help

function test_instance_monitoring_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "$0 ${namespace} [help|create|destroy|index|set_enable|show|update|xcreate]" "${res}"
}

### index

function test_instance_monitoring_index() {
  extract_args ${namespace} index i-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $? 
}

### show

function test_instance_monitoring_show() {
  extract_args ${namespace} show i-xxxxxxxx imon-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### create

function test_instance_monitoring_create() {
  extract_args ${namespace} create i-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### update

function test_instance_monitoring_update() {
  extract_args ${namespace} update i-xxxxxxxx imon-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### destroy

function test_instance_monitoring_destroy() {
  extract_args ${namespace} destroy i-xxxxxxxx imon-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### set_enable

function test_instance_monitoring_set_enable() {
  extract_args ${namespace} set_enable i-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
