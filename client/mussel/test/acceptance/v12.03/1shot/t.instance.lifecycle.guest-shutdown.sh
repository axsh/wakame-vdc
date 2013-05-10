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

ssh_user=${ssh_user:-root}

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	EOS
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

function test_wait_for_sshd_to_be_ready() {
  wait_for_sshd_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## guest shutdown

function test_guest_shutdown_instance() {
  remove_ssh_known_host_entry ${instance_ipaddr}

  ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "shutdown -h now"
  assertEquals 0 $?

  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?
}

## after guest shutdown

function test_wait_for_network_not_to_be_ready_after_stopping() {
  wait_for_network_not_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

function test_wait_for_sshd_not_to_be_ready_after_stopping() {
  wait_for_sshd_not_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

# shunit2

. ${shunit2_file}
