#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=volume

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### create

function test_volume_create() {
  local cmd=create

  local volume_size=10

  local opts=""

  local params="
    volume_size=${volume_size}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${size})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

### attach

function test_volume_attach() {
  local cmd=attach

  local opts=""

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?instance_id=${uuid}"
}

### detach

function test_volume_detach() {
  local cmd=detach

  local opts=""

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?instance_id=${uuid}"
}

## shunit2

. ${shunit2_file}
