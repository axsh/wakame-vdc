#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=base

## functions

function setUp() {
  state=
  uuid=asdf
}

### index

function test_base_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${DCMGR_BASE_URI}/${namespace}s.${format}?"
}

### show

function test_base_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${DCMGR_BASE_URI}/${namespace}s/${uuid}.${format}"
}

### destroy

function test_base_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${DCMGR_BASE_URI}/${namespace}s/${uuid}.${format}"
}

## shunit2

. ${shunit2_file}
