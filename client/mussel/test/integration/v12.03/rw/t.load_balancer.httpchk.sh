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

function test_create_load_balancer_httpchk() {

  local httpchk_path="/index.html"

  create_output="$(run_cmd load_balancer create)"
  assertEquals 0 $?
  assertEquals ${httpchk_path} $(echo "${create_output}" | hash_value httpchk_path)

  load_balancer_uuid=$(echo "${create_output}" | hash_value id)
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
