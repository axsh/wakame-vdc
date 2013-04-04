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

### load_balancer

function test_show_load_balancer_vifs() {
  assertNotEquals \
   "$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value vif_id | wc -l)" \
   "0"
}

## shunit2

. ${shunit2_file}
