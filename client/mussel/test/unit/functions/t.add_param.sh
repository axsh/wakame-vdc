#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function setUp() {
  :
}

function test_add_param_no_opts() {
  add_param >/dev/null 2>&1
  assertNotEquals 0 $?
}

function test_add_param_key_z() {
  add_param name
}

function test_add_param_key_n() {
  local name=i-xxx
  assertEquals "$(add_param name)" "name=${name}"
}

function test_add_param_key_string() {
  local name=i-xxx
  assertEquals "$(add_param name string)" "name=${name}"
}

function test_add_param_key_array() {
  local name=i-xxx
  assertEquals "$(add_param name array)" "name[]=${name}"
}

function test_add_param_key_array_multi() {
  local name="i-xxx i-yyy"
  assertNotEquals "$(add_param name array)" "$(for i in; do echo name[]=${i}; done)"
}

function test_add_param_key_strfile() {
  local name=i-xxx
  assertEquals "$(add_param name strfile)" "name=${name}"
}

function test_add_param_key_strplain() {
  local name=i-xxx
  assertEquals "$(add_param name strplain)" "${name}"
}

function test_add_param_key_hash() {
  local name="inst_id=i-xxx"
  assertEquals "$(add_param name hash)" "name[inst_id]=i-xxx"
}

function test_add_param_key_hash_multi() {
  local name="inst_id=i-xxx addr=bar"
  assertEquals "$(add_param name hash)" "name[inst_id]=i-xxx
name[addr]=bar"
}

function test_add_param_key_extended_hash_multi() {
  local name="volumes[0][type]=xxxx volumes[0][size]=50G"
  assertEquals "name[volumes[0][type]]=xxxx
name[volumes[0][size]]=50G" "$(add_param name hash)"
}

## shunit2

. ${shunit2_file}
