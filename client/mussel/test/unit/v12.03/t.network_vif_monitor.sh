#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=network_vif_monitor

## functions

### help

function test_network_vif_monitor_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "$0 ${namespace} [help|create|destroy|index|show|update|xcreate]" "${res}"
}

### index

function test_network_vif_monitor_index() {
  extract_args ${namespace} index i-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $? 
}

### show

function test_network_vif_monitor_show() {
  extract_args ${namespace} show i-xxxxxxxx nwm-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### create

function test_network_vif_monitor_create() {
  extract_args ${namespace} create i-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### update

function test_network_vif_monitor_update() {
  extract_args ${namespace} update i-xxxxxxxx nwm-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

### destroy

function test_network_vif_monitor_destroy() {
  extract_args ${namespace} destroy i-xxxxxxxx nwm-xxxxxxxx
  run_cmd ${MUSSEL_ARGS}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
