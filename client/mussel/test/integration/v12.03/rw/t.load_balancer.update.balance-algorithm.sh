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

function test_update_load_balancer_source() {
  load_balancer_uuid="$(run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"

  balance_algorithm="$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value balance_algorithm)"
  assertEquals "${balance_algorithm}" "leastconn"

  balance_algorithm=source run_cmd load_balancer update ${load_balancer_uuid}

  balance_algorithm="$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value balance_algorithm)"
  assertEquals "${balance_algorithm}" "source"
}

## shunit2

. ${shunit2_file}
