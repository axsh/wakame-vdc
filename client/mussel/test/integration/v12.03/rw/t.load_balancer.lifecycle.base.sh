#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

## functions

function oneTimeSetUp() {
  :
}

function oneTimeTearDown() {
  :
}

###

function test_create_load_balancer() {
  # :state: scheduling
  # :status: init
  load_balancer_uuid=$(run_cmd load_balancer create | hash_value id)
  assertEquals $? 0

  # :state: running
  # :status: init

  # :state: running
  # :status: online
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

function test_destroy_load_balancer() {
  # :state: shuttingdown
  # :status: online
  run_cmd load_balancer destroy ${load_balancer_uuid} >/dev/null
  assertEquals $? 0

  # :state: terminated
  # :status: offline
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state terminated"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
