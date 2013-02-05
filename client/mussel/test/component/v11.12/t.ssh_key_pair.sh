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

### create

function test_ssh_key_pair_create() {
  local cmd=create

  local params="
    name=${uuid}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.${DCMGR_RESPONSE_FORMAT}"
}

## shunit2

. ${shunit2_file}
