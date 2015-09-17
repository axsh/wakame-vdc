#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

rdp_user="${rdp_user:-"Administrator"}"

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:3389,3389,ip4:0.0.0.0/0
	EOS
}

### step

function test_get_instance_ipaddr() {
  instance_ipaddr="$(run_cmd instance show ${instance_uuid} | hash_value address)"
  assertEquals 0 $?
}

function test_wait_for_network_to_be_ready() {
  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

function test_wait_for_rdpd_to_be_ready() {
  wait_for_rdpd_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

function test_rdp_auth() {
  # 1: GET decrypted password
  plain_password="$(run_cmd instance decrypt_password ${instance_uuid} "${ssh_key_pair_path}")"
  assertEquals 0 $?

  echo "plain_password='${plain_password}'"
  [[ -n "${plain_password}" ]]

  # 2: rdp auth
  rdp_auth -u "${rdp_user}" -p "${plain_password}" "${instance_ipaddr}"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
