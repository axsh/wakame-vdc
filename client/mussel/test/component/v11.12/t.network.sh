#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=network

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_network_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

### show

function test_network_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### create

function test_network_create() {
  local cmd=create

  local gw=192.0.2.1
  local network=192.0.2.0
  local prefix=24
  local description=shunit2

  local params="
   --data-urlencode gw=${gw}
   --data-urlencode network=${network}
   --data-urlencode prefix=${prefix}
   --data-urlencode description=${description}
   "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X POST $(echo ${params}) ${base_uri}/${namespace}s.${format}"
}

### reserve

function test_network_reserve() {
  local cmd=reserve

  local ipaddr=192.0.2.10

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${ipaddr})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?ipaddr=${ipaddr}"
}

### release

function test_network_release() {
  local cmd=release

  local ipaddr=192.0.2.10

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${ipaddr})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?ipaddr=${ipaddr}"
}

### add_pool

function test_network_add_pool() {
  local cmd=add_pool

  local name=np-shunit2

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${name})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?name=${name}"
}

### del_pool

function test_network_del_pool() {
  local cmd=del_pool

  local name=np-shunit2

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${name})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?name=${name}"
}

### get_pool

function test_network_get_pool() {
  local cmd=get_pool

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

## shunit2

. ${shunit2_file}
