#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=network_vif

## functions

function setUp() {
  :
}

function tearDown() {
  :
}

### create

function test_network_vif_show_external_ip() {
  local uuid=shunit2

  local cmd=show_external_ip
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)"
}

function test_network_vif_attach_external_ip() {
  local uuid=shunit2
  local ip_handle_id=shunit2
  local opts="
    --ip-handle-id=${ip_handle_id}
  "
  local params="
    ip_handle_id=${ip_handle_id}
  "
  local cmd=attach_external_ip
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)"
}

function test_network_vif_detach_external_ip() {
  local uuid=shunit2
  local ip_handle_id=shunit2
  local opts="
    --ip-handle-id=${ip_handle_id}
  "
  local params="
    ip_handle_id=${ip_handle_id}
  "
  local cmd=detach_external_ip
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X DELETE $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)"
}

. ${shunit2_file}
