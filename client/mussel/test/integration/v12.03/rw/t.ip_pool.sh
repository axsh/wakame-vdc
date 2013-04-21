#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

ip_pool_uuid=
dc_networks="public"
display_name="shunit2"
ip_handle_uuid=

## functions

###

function test_create_ip_pool() {
  local opts="
    --dc-networks=${dc_networks}
    --display-name=${display_name}
  "
  ip_pool_uuid=$(run_cmd ip_pool create ${opts} | hash_value id)
  assertEquals $? 0
}

function test_show_ip_pool() {
  run_cmd ip_pool show ${ip_pool_uuid}
  assertEquals $? 0
}

function test_destroy_ip_pool() {
  run_cmd ip_pool destroy ${ip_pool_uuid}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
