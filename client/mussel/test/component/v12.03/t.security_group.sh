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
