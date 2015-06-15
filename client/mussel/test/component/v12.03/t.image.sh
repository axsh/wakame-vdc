#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=image

## functions

function setUp() {
  uuid=asdf
}

### update

function test_instance_update() {
  local cmd=update

  local display_name=shunit2

  local params="
    display_name=${display_name}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}.$(suffix)"
}

## shunit2

. ${shunit2_file}
