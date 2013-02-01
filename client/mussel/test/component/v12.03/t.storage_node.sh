#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

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

### xcreate

function test_storage_node_xcreate() {
  local cmd=xcreate

  local MUSSEL_CUSTOM_DATA="
    --data-urlencode name=shunit2
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=${MUSSEL_CUSTOM_DATA} cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(echo ${MUSSEL_CUSTOM_DATA}) ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
