#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=security_group

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### create

function test_security_group_create() {
  local cmd=create

  local description=description
  local rule=tcp:22,22,0.0.0.0

  local opts=""

  local params="
    description=${description}
    rule=${rule}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${description} ${rule})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

### update

function test_security_group_update() {
  local cmd=update

  local rule=tcp:22,22,0.0.0.0

  local opts=""

  local params="
    rule=${rule}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${rule})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}.$(suffix)"
}

## shunit2

. ${shunit2_file}
