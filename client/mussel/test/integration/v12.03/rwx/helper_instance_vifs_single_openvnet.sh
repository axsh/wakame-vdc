#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

dc_network=$(run_cmd dc_network index | hash_value id)
vnet_uuid=$(run_cmd network create | extract_uuid nw)

## functions

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vnet_uuid}","security_groups":"${security_group_uuid}"}}
	EOS
}
