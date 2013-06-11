#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})

## functions

###

function base_index_uuids() {
  base_index | grep -- '^  - :id:' | awk -F :id: '{print $2}'
}

function test_index() {
  step_base_index
}

function test_show_uuids() {
  step_base_show_uuids
}

function test_show_invalid_uuid_syntax() {
  step_base_show_invalid_uuid_syntax
}

## shunit2

. ${shunit2_file}
