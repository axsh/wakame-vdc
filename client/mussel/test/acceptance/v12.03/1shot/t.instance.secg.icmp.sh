#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_single.sh

## variables

declare instance_ipaddr=

function needs_vif() { true; }
function needs_secg() { true; }

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	EOS
}

function after_create_instance() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  wait_for_network_to_be_ready ${instance_ipaddr}
}

### step

function test_drop_icmp() {
  cat <<-EOS > ${rule_path}
	#
	EOS
  run_cmd security_group update ${security_group_uuid}
  sleep 3

  wait_for_network_not_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

function test_accept_icmp() {
  render_secg_rule > ${rule_path}
  run_cmd security_group update ${security_group_uuid}
  sleep 3

  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
