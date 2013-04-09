#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

### optional

## functions

function oneTimeSetUp() {
  :
}

function oneTimeTearDown() {
  :
}

function setUp() {
  :
}

function tearDown() {
  destroy_load_balancer
}

###

function test_create_load_balancer_allow_list_cidr() {
  load_balancer_uuid="$(allow_list=216.98.224.0/20 run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

function test_create_load_balancer_allow_list_cidr_array() {
  load_balancer_uuid="$(allow_list="216.98.224.0/20 216.99.10.0/20" run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

function test_create_load_balancer_allow_list_ip() {
  load_balancer_uuid="$(allow_list=216.98.224.99 run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

function test_create_load_balancer_allow_list_ip_array() {
  load_balancer_uuid="$(allow_list="216.98.224.99 216.98.224.98" run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
