#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=storage_node

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_storage_node_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

### show

function test_storage_node_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### destroy

function test_storage_node_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

### xcreate

function test_storage_node_xcreate() {
  local cmd=xcreate

  local MUSSEL_CUSTOM_DATA="
    name=shunit2
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
