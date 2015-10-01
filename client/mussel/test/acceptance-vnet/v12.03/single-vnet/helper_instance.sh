#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

VNMGR_HOST=${VNMGR_HOST:-localhost}
VNMGR_PORT=${VNMGR_PORT:-9090}
datapath_uuid=$(curl -s -X GET http://${VNMGR_HOST}:${VNMGR_PORT}/api/1.0/datapaths.yaml | hash_value uuid)

dc_network=$(run_cmd dc_network index | hash_value id)
network="10.197.0.0"
prefix=24
network_mode=l2overlay
service_dhcp="10.197.0.1"
dhcp_range="default"
network_uuid=$(run_cmd network create | hash_value id | grep "nw-")

# interfaces=$(curl -s -X GET http://${VNMGR_HOST}:${VNMGR_PORT}/api/1.0/interfaces.yaml | hash_value uuid | grep "if-")
# interface_uuid=""
# for i in ${interfaces}; do
#   ii=$(curl -s -X GET http://${VNMGR_HOST}:${VNMGR_PORT}/api/1.0/interfaces/${i}.yaml | grep host)
#   if [[ ! -z ${ii} ]]; then
#     interface_uuid=${i}
#   fi
# done
# datapath_network_uuid=$(curl -s -X POST --data-urlencode interface_uuid=${interface_uuid} http://${VNMGR_HOST}:${VNMGR_PORT}/api/1.0/datapaths/${datapath_uuid}/networks/${network_uuid}.yaml | hash_value uuid)


## functions

function needs_vif() { true; }

function render_vif_table() {
  cat <<-EOS
	{
	"eth0":{"index":"0","network":"${network_uuid}"},
	"eth1":{"index":"1","network":"nw-demo8"}
	}
	EOS
}

### shunit2 setup

function oneTimeSetUp() {
  create_instance
}

function oneTimeTearDown() {
  :
  # destroy_instance
}
