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

## functions

###

function test_create_ip_pool() {
  local dc_networks=${dc_networks}
  local display_name=${display_name}
  ip_pool_id=$(run_cmd ip_pool create | hash_value id)
  assertEquals 0 $?
}

function test_show_ip_pool() {
  run_cmd ip_pool show ${ip_pool_id}
  assertEquals 0 $?
}

function test_destroy_ip_pool() {
  run_cmd ip_pool destroy ${ip_pool_id}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
