#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

## functions

function needs_vif() { true; }
function needs_secg() { true; }

### instance

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	EOS
}

function after_create_instance() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
}

function oneTimeSetUp() {
  create_instance
}

function oneTimeTearDown() {
  destroy_instance
}

### shunit2 setup
