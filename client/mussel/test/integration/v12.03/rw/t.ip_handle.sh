#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

ip_pool_id=
dc_networks="public"
display_name="shunit2"
network_id=nw-demo1
ip_handle_id=

## functions

###

function setUp() {
  local dc_networks=${dc_networks}
  local display_name=${display_name}
  ip_pool_id=$(run_cmd ip_pool create | hash_value id)
  ip_handle_id=$(run_cmd ip_pool acquire ${ip_pool_id} | hash_value ip_handle_id)
}

function test_show_ip_handle() {
  run_cmd ip_handle show ${ip_handle_id}
  assertEquals 0 $?
}

function test_update_ip_handle_expire_at() {
  local time_to=1
  run_cmd ip_handle expire_at ${ip_handle_id}
  assertEquals 0 $?
}

function tearDown() {
  run_cmd ip_pool destroy ${ip_pool_id}
}

## shunit2

. ${shunit2_file}
