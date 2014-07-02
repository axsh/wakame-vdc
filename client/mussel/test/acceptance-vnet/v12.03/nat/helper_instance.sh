#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}
ip_pool_id=${ip_pool_id:-ipp-external}

## functions

function needs_vif() { true; }

function render_vif_table() {
  cat <<-EOS
	{
	"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":""},
	"eth1":{"index":"1","network":"nw-demo8","security_groups":""}
	}
	EOS
}

### shunit2 setup

function oneTimeSetUp() {
  create_instance
}

function oneTimeTearDown() {
  destroy_instance
}
