#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_single.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_login.sh

## variables

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
}

### step

function test_wait_for_instance_network_is_ready() {
  wait_for_instance_network_is_ready
  assertEquals $? 0
}

function test_wait_for_instance_sshd_is_ready() {
  wait_for_instance_sshd_is_ready
  assertEquals $? 0
}

function test_remove_ssh_known_host_entry() {
  remove_ssh_known_host_entry
  assertEquals $? 0
}

function test_compare_instance_hostname() {
  local ipaddr=$(get_instance_ipaddr)
  assertEquals \
    "$(run_cmd instance show ${instance_uuid} | hash_value hostname)" \
    "$(ssh root@${ipaddr} -i ${ssh_key_pair_path} hostname)"
}

## shunit2

. ${shunit2_file}
