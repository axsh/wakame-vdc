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

function test_network_create() {
  local cmd=create

  local opts="
    --account_id=a-shpoolxx
    --display_name=virtual
    --network_mode=virtual
    --description=vnet
    --domain_name=vnet
    --prefix=24
    --service_dhcp=10.100.0.1
  "

  local params="
    description=vnet
    display_name=virtual
    domain_name=vnet
    network_mode=virtual
    prefix=24
    service_dhcp=10.100.0.1
    account_id=a-shpoolxx
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s"
}

## shunit2

. ${shunit2_file}
