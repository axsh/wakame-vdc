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

### index

function test_security_group_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

### show

function test_security_group_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### destroy

function test_security_group_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

### xcreate

function test_security_group_xcreate() {
  local cmd=xcreate

  local MUSSEL_CUSTOM_DATA="
    name=shunit2
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) ${base_uri}/${namespace}s.${format}"
}

### create

function test_security_group_create_no_opts() {
  local cmd=create

  local service_type=std
  local rule=tcp:22,22,ip4:0.0.0.0/0
  local description=shunit2
  local display_name=foo

  local opts=""

  local params="
    service_type=${service_type}
    rule=${rule}
    description=${description}
    display_name=${display_name}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_security_group_create_opts() {
  local cmd=create

  local service_type=std
  local rule=tcp:22,22,ip4:0.0.0.0/0
  local description=shunit2
  local display_name=foo

  local opts="
    --service-type=${service_type}
    --rule=${rule}
    --description=${description}
    --display-name=${display_name}
  "

  local params="
    service_type=${service_type}
    rule=${rule}
    description=${description}
    display_name=${display_name}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
