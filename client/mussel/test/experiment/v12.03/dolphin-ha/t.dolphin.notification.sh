#!/bin/bash
#
#
#

## include files
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_dolphin.sh

## variables

## functions
function render_email_address() {
  cat <<-EOS
	{"email":{"to":"example@axsh.net"}}
	EOS
}

## shunit2 setup
function oneTimeSetUp() {
  setup_email
}

function oneTimeTearDown() {
  delete_email
}

## step

# API test for create new notification.
function test_create_new_notification() {
  notification_id=11 email=${email} run_cmd notification create
  assertEquals 0 $?
} 

# API test for get notification.
function test_get_notification() {
  run_cmd notification show 11
  assertEquals 0 $?
}

# API test for delete notification.
function test_delete_notification() {
  run_cmd notification destroy 11
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}
