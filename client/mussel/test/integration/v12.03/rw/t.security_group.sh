#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare security_group_uuid= rule=

## functions

###

function test_create_security_group() {
  rule=tcp:22,22,ip4:0.0.0.0/0
  security_group_uuid=$(run_cmd security_group create | hash_value id)
  assertEquals $? 0
}

function test_show_security_group() {
  run_cmd security_group show ${security_group_uuid} >/dev/null
  assertEquals $? 0
}

function test_update_security_group_icmp() {
  rule=icmp:-1,-1,ip4:0.0.0.0/0
  run_cmd security_group update ${security_group_uuid} >/dev/null
  assertEquals $? 0
}

function test_update_security_group_udp() {
  rule=udp:53,53,ip4:0.0.0.0/0
  run_cmd security_group update ${security_group_uuid} >/dev/null
  assertEquals $? 0
}

function test_destroy_security_group() {
  run_cmd security_group destroy ${security_group_uuid} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
