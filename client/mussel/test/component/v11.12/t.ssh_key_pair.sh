#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ssh_key_pair

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_ssh_key_pair_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

### show

function test_ssh_key_pair_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### create

function test_ssh_key_pair_create() {
  local cmd=create

  local params="
    name=${uuid}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

### destroy

function test_ssh_key_pair_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

## shunit2

. ${shunit2_file}
