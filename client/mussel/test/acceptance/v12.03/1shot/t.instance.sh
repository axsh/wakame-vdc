#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

# configuarable variables

image_id=${image_id:-wmi-centos1d}
hypervisor=${hypervisor:-openvz}
cpu_cores=${cpu_cores:-1}
memory_size=${memory_size:-256}
network_id=${network_id:-nw-demo1}

# test local variables

declare inst_id=
declare inst_hash=
declare ipaddr=

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

function generate_ssh_key_pair() {
  ssh-keygen -N "" -f ${ssh_keypair_path} -C shunit2.$$ >/dev/null
}

function create_ssh_key_pair() {
  public_key=${ssh_keypair_path}.pub
  ssh_key_id=$(run_cmd ssh_key_pair create | hash_value id)
}

function create_security_group() {
  render_secg_rule > ${rule_path}
  rule=${rule_path}
  secg_id=$(run_cmd security_group create | hash_value id)
}

function create_instance() {
  render_vif_table > ${vifs_path}
  vifs=${vifs_path}

  inst_id=$(run_cmd instance create | hash_value id)
}

function wait_for_instance_state_is_running() {
  retry_until ${wait_sec} "check_document_pair instance ${inst_id} state running"
}

function wait_for_instance_state_is_terminated() {
  retry_until ${wait_sec} "check_document_pair instance ${inst_id} state terminated"
}

function destroy_instance() {
  run_cmd instance destroy ${inst_id}
}

function destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_id}
}

function destroy_security_group() {
  run_cmd security_group destroy ${secg_id}
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
  ipaddr=$(run_cmd instance show ${inst_id} | hash_value address)
  retry_until ${wait_sec} "check_network_connection ${ipaddr}" >/dev/null
  assertEquals $? 0
}

function test_wait_for_instance_sshd_is_ready() {
  ipaddr=$(run_cmd instance show ${inst_id} | hash_value address)
  retry_until ${wait_sec} "check_port ${ipaddr} tcp 22" >/dev/null
  assertEquals $? 0
}

function test_remove_ssh_known_host_entry() {
  ipaddr=$(run_cmd instance show ${inst_id} | hash_value address)
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
  assertEquals $? 0
}

function test_compare_instance_hostname() {
  ipaddr=$(run_cmd instance show ${inst_id} | hash_value address)
  assertEquals \
    "$(run_cmd instance show ${inst_id} | hash_value hostname)" \
    "$(ssh root@${ipaddr} -i ${ssh_keypair_path} hostname)"
}

function test_compare_instance_ipaddr() {
  ipaddr=$(run_cmd instance show ${inst_id} | hash_value address)
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
