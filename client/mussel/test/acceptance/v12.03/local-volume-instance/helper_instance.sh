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

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}
ssh_user=${ssh_user:-root}
blank_volume_size=${blank_volume_size:-10M}

## functions

function remote_sudo() {
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-'EOS'
	case "${UID}" in
	0) ;;
	*) echo sudo ;;
	esac
	EOS
}

function blank_dev_path() {
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-'EOS'
	[[ -b /dev/vdc ]] && echo /dev/vdc
	[[ -b /dev/sdc ]] && echo /dev/sdc
	EOS
}

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

function before_create_instance() {
  # boot instance with second blank volume.
  if is_container_hypervisor; then
    volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=local volumes[0][guest_device_name]=/dev/vdc"
  else
    volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=local"
  fi
}

function after_create_instance() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  wait_for_network_to_be_ready ${instance_ipaddr}
  wait_for_sshd_to_be_ready    ${instance_ipaddr}
  boot_volume_uuid=$(run_cmd instance show ${instance_uuid} | hash_value boot_volume_id)
}

### shunit2 setup

function oneTimeSetUp() {
  create_instance
}

function oneTimeTearDown() {
  destroy_instance
}
