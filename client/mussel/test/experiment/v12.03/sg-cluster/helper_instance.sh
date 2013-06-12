#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_ipaddr=
declare instance_uuids_path=$(generate_cache_file_path instance_uuids)

function needs_vif() { true; }
function needs_secg() { true; }

ssh_user=${ssh_user:-root}
image_id=${image_id_lbnode:-wmi-lbnode}
vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

api_client_addr=$(for i in $(ip route get ${DCMGR_HOST} | head -1); do echo ${i}; done | tail -1)

## functions

### instance

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:${api_client_addr}/32
	tcp:22,22,ip4:${api_client_addr}/32
	EOS
}

function oneTimeSetUp() {
  # create
  for i in $(eval echo "{1..${target_instance_num:-1}}"); do
    create_instance
    echo ${instance_uuid} >> ${instance_uuids_path}
  done

  # wait
  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr="$(cached_instance_param ${instance_uuid} | hash_value address)"
    wait_for_network_to_be_ready ${instance_ipaddr}
    wait_for_sshd_to_be_ready    ${instance_ipaddr}
  done
}

function oneTimeTearDown() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    ssh_key_pair_uuid="$(cached_instance_param ${instance_uuid}   | egrep ' ssh-' | awk '{print $2}')"
    security_group_uuid="$(cached_instance_param ${instance_uuid} | egrep ' sg-'  | awk '{print $2}')"
    destroy_instance
  done

  rm -f ${instance_uuids_path}
}
