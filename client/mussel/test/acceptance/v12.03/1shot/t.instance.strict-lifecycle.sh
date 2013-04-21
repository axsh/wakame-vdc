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
	tcp:22,22,ip4:0.0.0.0/0
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
  assertEquals $? 0
}

function test_wait_for_network_to_be_ready() {
  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

function test_wait_for_sshd_to_be_ready() {
  wait_for_sshd_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## login to the instance

function test_compare_instance_hostname() {
  assertEquals \
    "$(run_cmd instance show ${instance_uuid} | hash_value hostname)" \
    "$(ssh root@${instance_ipaddr} -i ${ssh_key_pair_path} hostname)"
}

## running -> stop

function test_stop_instance() {
  run_cmd instance stop ${instance_uuid} >/dev/null
  assertEquals $? 0

  retry_until "document_pair? instance ${instance_uuid} state stopped"
  assertEquals $? 0
}

function test_wait_for_network_not_to_be_ready_after_stopping() {
  wait_for_network_not_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## halted  -> start

function test_start_instance() {
  run_cmd instance start ${instance_uuid} >/dev/null
  assertEquals $? 0

  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals $? 0
}

function test_wait_for_network_to_be_ready_after_starting() {
  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## after terminating

function test_destroy_instance() {
  _destroy_instance
  assertEquals $? 0
}

function test_wait_for_network_not_to_be_ready_after_terminating() {
  wait_for_network_not_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

function test_wait_for_sshd_not_to_be_ready_after_terminating() {
  wait_for_sshd_not_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
