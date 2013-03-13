#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

## functions

### step

function test_get_load_balancer_ipaddr() {
  load_balancer_ipaddr=$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value address | head -1)
  assertEquals $? 0
}

function test_wait_for_network_to_be_ready() {
  wait_for_network_to_be_ready ${load_balancer_ipaddr}
  assertEquals $? 0
}

function test_wait_for_load_balancer_port_to_be_ready() {
  local port=$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value port)
  wait_for_port_to_be_ready ${load_balancer_ipaddr} tcp ${port}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
