#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

rule_path=${BASH_SOURCE[0]%/*}/rule.$$
rule=${rule_path}

## functions

function oneTimeTearDown() {
  rm -f ${rule_path}
}

###

function test_create_sg() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	EOS
  sg_uuid=$(run_cmd security_group create | hash_value id)
  assertEquals $? 0
}

function test_allow_self_sg() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,${sg_uuid}
	EOS
  run_cmd security_group update ${sg_uuid}
  assertEquals $? 0
}

function test_destroy_self_referred_sg() {
  run_cmd security_group destroy ${sg_uuid}
  assertNotEquals $? 0
}

function test_flush_sg() {
  cat <<-EOS > ${rule_path}
	#
	EOS
  run_cmd security_group update ${sg_uuid}
  assertEquals $? 0
}

function test_destroy_sg() {
  run_cmd security_group destroy ${sg_uuid}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
