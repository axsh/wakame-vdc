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

function test_poweroff_load_balancer() {
  # :state: halting
  # :status: online
  run_cmd load_balancer poweroff ${load_balancer_uuid} >/dev/null
  assertEquals $? 0

  # :state: halted
  # :status: online
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state halted"
  assertEquals $? 0
}

function test_poweron_load_balancer() {
  # :state: starting
  # :status: online
  run_cmd load_balancer poweron ${load_balancer_uuid} >/dev/null
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
