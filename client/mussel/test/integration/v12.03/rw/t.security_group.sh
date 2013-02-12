#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})
declare uuid= rule=

## functions

###

function test_create_security_group() {
  rule=tcp:22,22,ip4:0.0.0.0/0
  uuid=$(run_cmd ${namespace} create | awk '$1 == ":id:" {print $2}')
  assertEquals $? 0
}

function test_show_security_group() {
  run_cmd ${namespace} show ${uuid} >/dev/null
  assertEquals $? 0
}

function test_update_security_group_icmp() {
  rule=icmp:-1,-1,ip4:0.0.0.0/0
  run_cmd ${namespace} update ${uuid} >/dev/null
  assertEquals $? 0
}

function test_update_security_group_udp() {
  rule=udp:53,53,ip4:0.0.0.0/0
  run_cmd ${namespace} update ${uuid} >/dev/null
  assertEquals $? 0
}

function test_destroy_security_group() {
  run_cmd ${namespace} destroy ${uuid} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
