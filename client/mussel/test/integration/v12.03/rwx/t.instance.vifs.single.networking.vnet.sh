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

function test_show_instance_vifs_single_networking_vnet() {
  run_cmd instance show ${instance_uuid}
}

function test_show_instance_vifs_interfaces_corresponded_on_vnet() {
  vdc_networkvif_uuid=$(run_cmd instance show ${instance_uuid} | hash_value vif_id | sed -e 's/vif/if/g')
  vnet_interface_uuid=$(curl -fsSkL -X GET http://${DCMGR_HOST}:9090/api/interfaces/${vdc_networkvif_uuid} | extract_uuid if)

  asserEquals ${vdc_networkvif_uuid} ${vnet_interface_uuid}
}

## shunit2

. ${shunit2_file}
