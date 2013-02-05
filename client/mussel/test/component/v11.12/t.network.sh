#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=network

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### create

function test_network_create() {
  local cmd=create

  local gw=192.0.2.1
  local network=192.0.2.0
  local prefix=24
  local description=shunit2

  local params="
    gw=${gw}
    network=${network}
    prefix=${prefix}
    description=${description}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X POST $(urlencode_data ${params}) ${DCMGR_BASE_URI}/${namespace}s.${DCMGR_RESPONSE_FORMAT}"
}

### reserve

function test_network_reserve() {
  local cmd=reserve

  local ipaddr=192.0.2.10

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${ipaddr})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${DCMGR_RESPONSE_FORMAT}?ipaddr=${ipaddr}"
}

### release

function test_network_release() {
  local cmd=release

  local ipaddr=192.0.2.10

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${ipaddr})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${DCMGR_RESPONSE_FORMAT}?ipaddr=${ipaddr}"
}

### add_pool

function test_network_add_pool() {
  local cmd=add_pool

  local name=np-shunit2

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${name})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${DCMGR_RESPONSE_FORMAT}?name=${name}"
}

### del_pool

function test_network_del_pool() {
  local cmd=del_pool

  local name=np-shunit2

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${name})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${DCMGR_RESPONSE_FORMAT}?name=${name}"
}

### get_pool

function test_network_get_pool() {
  local cmd=get_pool

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${DCMGR_RESPONSE_FORMAT}"
}

## shunit2

. ${shunit2_file}
