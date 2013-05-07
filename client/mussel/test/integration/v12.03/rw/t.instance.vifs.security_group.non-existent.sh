#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function oneTimeSetUp() {
  create_ssh_key_pair
}

function oneTimeTearDown() {
  destroy_ssh_key_pair
}

function render_vif_table() {
  cat <<-EOS
	{
	"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"sg-nonexistent"}
	}
	EOS
}

###

function test_show_instance_vifs_null() {
  render_vif_table > ${vifs_path}
  vifs=${vifs_path}
  echo vifs
  cat ${vifs_path}

  run_cmd instance create

  assertNotEquals "status code should not be 0" 0 $?
}

## shunit2

. ${shunit2_file}
