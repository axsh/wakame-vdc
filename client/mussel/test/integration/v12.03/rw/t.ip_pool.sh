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

function test_acquire_ip_handle_from_ip_handle() {
  local network_id=${network_id}
  ip_handle_id=$(run_cmd ip_pool acquire ${ip_pool_id} | hash_value ip_handle_id)
  [[ -n "${ip_handle_id}" ]]
  assertEquals 0 $?
}

function test_list_ip_handles_of_ip_pool() {
  run_cmd ip_pool ip_handles ${ip_pool_id}
  assertEquals 0 $?
}

function test_release_ip_handle_from_ip_handle() {
  local network_id=${network_id} ip_handle_id=${ip_handle_id}
  run_cmd ip_pool release ${ip_pool_id}
  assertEquals 0 $?
}

function test_destroy_ip_pool() {
  run_cmd ip_pool destroy ${ip_pool_id}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
