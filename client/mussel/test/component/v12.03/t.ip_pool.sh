#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ip_pool

## functions

function setUp() {
  :
}

function tearDown() {
  :
}

### create

function test_ip_pool_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET $(base_uri)/${namespace}s.$(suffix)"
}
function test_ip_pool_create() {
  local cmd=create
  local dc_networks=public
  local display_name=shunit2
  local opts="
    --dc-networks=${dc_networks}
    --display-name=${display_name}
  "

  local params="
    dc_networks[]=${dc_networks}
    display_name=${display_name}
  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

function test_ip_pool_destroy() {
  local cmd=destroy
  local uuid=shunit2
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE $(base_uri)/${namespace}s/${uuid}.$(suffix)"
}

function test_ip_pool_ip_handles() {
  local cmd=ip_handles
  local uuid=shunit2
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

function test_ip_pool_acquire() {
  local cmd=acquire
  local uuid=shunit2
  local network_id=shunit2
  local opts="
    --network-id=${network_id}
  "

  local params="
    network_id=${network_id}
  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

function test_ip_pool_release() {
  local cmd=release
  local uuid=shunit2
  local ip_handle_id=shunit2
  local opts="
    --ip-handle-id=${ip_handle_id}
  "

  local params="
    ip_handle_id=${ip_handle_id}
  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

## shunit2

. ${shunit2_file}
