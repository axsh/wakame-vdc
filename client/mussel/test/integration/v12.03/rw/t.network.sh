
#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## functions

function test_network_create() {
  dc_network=$(run_cmd dc_network index | hash_value id)
  vdc_network_uuid=$(run_cmd network create | extract_uuid nw)
  vnet_network_uuid=$(curl -fsSkL -X GET http://${DCMGR_HOST}:9090/api/networks/${vdc_network_uuid} | extract_uuid nw)

  echo "vdc_network_uuid = ${vdc_network_uuid}"
  echo "vnet_network_uuid = ${vnet_network_uuid}"

  assertEquals ${vnet_network_uuid} ${vdc_network_uuid}
}


## shunit2

. ${shunit2_file}
