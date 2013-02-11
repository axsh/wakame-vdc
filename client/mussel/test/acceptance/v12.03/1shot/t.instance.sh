#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function oneTimeTearDown() {
  rm -f ${ssh_keypair_path}*
  rm -f ${vifs_path}
  rm -f ${rule_path}
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
}

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${network_id}","security_groups":"${secg_id}"}}
	EOS
}

### step

function test_generate_ssh_key_pair() {
  generate_ssh_key_pair >/dev/null
  assertEquals $? 0
}

function test_create_ssh_key_pair() {
  create_ssh_key_pair
  assertEquals $? 0
}

function test_create_security_group() {
  create_security_group
  assertEquals $? 0
}

function test_create_instance() {
  create_instance
  assertEquals $? 0
}

function test_wait_for_instance_state_is_running() {
  wait_for_instance_state_is_running
  assertEquals $? 0
}

function test_wait_for_instance_network_is_ready() {
  wait_for_instance_network_is_ready
  assertEquals $? 0
}

function test_wait_for_instance_sshd_is_ready() {
  wait_for_instance_sshd_is_ready
  assertEquals $? 0
}

function test_remove_ssh_known_host_entry() {
  remove_ssh_known_host_entry >/dev/null 2>&1
  assertEquals $? 0
}

function test_compare_instance_hostname() {
  ipaddr=$(get_instance_ipaddr)
  assertEquals \
    "$(run_cmd instance show ${inst_id} | hash_value hostname)" \
    "$(ssh root@${ipaddr} -i ${ssh_keypair_path} hostname)"
}

function test_compare_instance_ipaddr() {
  ipaddr=$(get_instance_ipaddr)
  ssh root@${ipaddr} -i ${ssh_keypair_path} ip addr show eth0 | egrep -q ${ipaddr}
  assertEquals $? 0
}

function test_destroy_instance() {
  destroy_instance >/dev/null
  assertEquals $? 0
}

function test_wait_for_instance_state_is_terminated() {
  wait_for_instance_state_is_terminated
  assertEquals $? 0
}

function test_destroy_ssh_key_pair() {
  destroy_ssh_key_pair >/dev/null
  assertEquals $? 0
}

function test_destroy_security_group() {
  destroy_security_group >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
