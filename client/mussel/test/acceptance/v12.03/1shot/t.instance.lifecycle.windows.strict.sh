#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:3389,3389,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
}

function destroy_instance() {
  :
}

### step

## after creating

function test_get_instance_ipaddr() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  assertEquals 0 $?
}

function test_wait_for_network_to_be_ready() {
  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

## after terminating

function test_destroy_instance() {
  _destroy_instance
  assertEquals 0 $?
}

function test_wait_for_network_not_to_be_ready_after_terminating() {
  wait_for_network_not_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
