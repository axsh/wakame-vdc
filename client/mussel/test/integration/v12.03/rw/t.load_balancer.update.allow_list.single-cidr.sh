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

function test_update_load_balancer_allow_list_single_cidr() {
  load_balancer_uuid="$(run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"

  expected="- 0.0.0.0
:httpchk_path: ''"
  allow_list="$(run_cmd load_balancer show ${load_balancer_uuid} | grep -A 2 ":allow_list:" | awk 'NR==2,NR==3{print}')"
  assertEquals "${allow_list}" "${expected}"

  allow_list=192.0.2.0/24 run_cmd load_balancer update ${load_balancer_uuid}

  expected="- 192.0.2.0/24
:httpchk_path: ''"
  allow_list="$(run_cmd load_balancer show ${load_balancer_uuid} | grep -A 2 ":allow_list:" | awk 'NR==2,NR==3{print}')"
  assertEquals "${allow_list}" "${expected}"
}

## shunit2

. ${shunit2_file}
