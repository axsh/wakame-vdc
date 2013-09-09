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

function test_create_nested_sg() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	EOS
  core_sg=$(run_cmd security_group create | hash_value id)
  assertEquals 0 $?

  cat <<-EOS > ${rule_path}
	icmp:-1,-1,${core_sg}
	EOS
  shell_sg=$(run_cmd security_group create | hash_value id)
  assertEquals 0 $?
}

function test_destroy_core_sg_before_destroying_shell_sg() {
  run_cmd security_group destroy ${core_sg}
  assertNotEquals $? 0
}

function test_destroy_nested_sg() {
  run_cmd security_group destroy ${shell_sg}
  assertEquals 0 $?

  run_cmd security_group destroy ${core_sg}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
