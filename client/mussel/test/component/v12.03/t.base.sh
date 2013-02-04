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

### xcreate

function test_base_xcreate() {
  local cmd=xcreate

  local MUSSEL_CUSTOM_DATA="
    name=shunit2
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) ${DCMGR_BASE_URI}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
