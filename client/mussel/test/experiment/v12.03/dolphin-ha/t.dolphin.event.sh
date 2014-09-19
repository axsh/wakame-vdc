#!/bin/bash
#
#
#

## include files
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_dolphin.sh

## variables
event=${event:-'{}'}
event_path=${event_path:-${BASH_SOURCE[0]%/*}/event.$$}

## functions
function render_message() {
  cat <<-EOS
	{"alert":"sample"}
	EOS
}

function render_event() {
  run_cmd event index | $(json_sh) | grep id | sort -nr | awk '{print $3}' | head -1 > ${event_path}
}

function delete_event() {
  rm -f ${event_path}
}

## shunit2 setup
function oneTimeSetUp() {
  setup_message
}

function oneTimeTearDown() {
  delete_message
  delete_event
}

## step

# API test for create new event.
function test_create_new_event() {
  message=${message} run_cmd event create
  assertEquals 0 $?
}

# API test for get events
function test_get_events() {
  run_cmd event index
  assertEquals 0 $?
}
 
# API test for get event
function test_get_event() {
  render_event
  run_cmd event show $(cat ${event_path})
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}

