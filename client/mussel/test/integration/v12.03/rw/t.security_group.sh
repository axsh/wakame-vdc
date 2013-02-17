#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

security_group_uuid=
rule_path=${BASH_SOURCE[0]%/*}/rule.$$
rule=${rule_path}

## functions

function oneTimeTearDown() {
  rm -f ${rule_path}
}

###

function test_create_security_group() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
  security_group_uuid=$(run_cmd security_group create | hash_value id)
  assertEquals $? 0
}

function test_show_security_group() {
  run_cmd security_group show ${security_group_uuid}
  assertEquals $? 0
}

function test_update_security_group_icmp() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	EOS
  run_cmd security_group update ${security_group_uuid}
  assertEquals $? 0
}

function test_update_security_group_udp() {
  cat <<-EOS > ${rule_path}
	udp:53,53,ip4:0.0.0.0/0
	EOS
  run_cmd security_group update ${security_group_uuid}
  assertEquals $? 0
}

function test_flush_rule() {
  cat <<-EOS > ${rule_path}
	#
	EOS
  run_cmd security_group update ${security_group_uuid}
  assertEquals $? 0
}

function test_destroy_security_group() {
  run_cmd security_group destroy ${security_group_uuid}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
