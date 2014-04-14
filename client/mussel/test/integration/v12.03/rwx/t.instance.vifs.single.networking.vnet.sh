#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_single_openvnet.sh

## variables

function needs_vif() { true; }
function needs_secg() { true; }

## functions

###

function test_show_instance_vifs_interfaces_corresponded_on_vnet() {
  vdc_networkvif_uuid=$(run_cmd instance show ${instance_uuid} | hash_value vif_id | sed -e 's/vif/if/g')
  vnet_interface_uuid=$(curl -fsSkL -X GET http://${DCMGR_HOST}:9090/api/interfaces/${vdc_networkvif_uuid}.$(suffix) | hash_value uuid | awk '{if(match($0, /if-[0-9a-zA-Z]+/)){print substr($0, RSTART, RLENGTH);}}')

  echo "vdc_networkvif_uuid = ${vdc_networkvif_uuid}"
  echo "vnet_interface_uuid = ${vnet_interface_uuid}"

  assertEquals ${vdc_networkvif_uuid} ${vnet_interface_uuid}
}

## shunit2

. ${shunit2_file}
