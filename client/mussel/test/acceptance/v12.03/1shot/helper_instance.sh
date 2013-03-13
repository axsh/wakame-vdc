#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

## functions

### instance

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

### shunit2 setup

function oneTimeSetUp() {
  create_instance
}

function oneTimeTearDown() {
  destroy_instance
}

