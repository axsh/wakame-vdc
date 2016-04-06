#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_ipaddr=

function needs_vif() { true; }
function needs_secg() { true; }

# image_id= [ wmi-windows2008r2 | wmi-windows2012r2 ]
vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}
cpu_cores=1
memory_size=1024
retry_wait_sec_for_windows_boot="${retry_wait_sec_for_windows_boot:-"$((60 * 10))"}"

## functions

### instance

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

### shunit2 setup

function oneTimeSetUp() {
  OLD_RETRY_WAIT_SEC=${RETRY_WAIT_SEC}
  export RETRY_WAIT_SEC="${retry_wait_sec_for_windows_boot}"

  create_instance

  export RETRY_WAIT_SEC=${OLD_RETRY_WAIT_SEC}
  export OLD_RETRY_WAIT_SEC=
}

function oneTimeTearDown() {
  destroy_instance
}
