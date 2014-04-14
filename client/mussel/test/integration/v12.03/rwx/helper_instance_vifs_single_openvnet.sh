#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

dc_network=$(run_cmd dc_network index | hash_value id)
vdc_network_uuid=$(run_cmd network create | hash_value network_id)

## functions

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vdc_network_uuid}","security_groups":"${security_group_uuid}"}}
	EOS
}
