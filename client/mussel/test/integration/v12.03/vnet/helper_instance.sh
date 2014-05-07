#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

instance_ipaddr=
instance_uuids_path=$(generate_cache_file_path instance_uuids)

dc_network=$(run_cmd dc_network index | hash_value id)
vdc_network_uuid=$(run_cmd network create | hash_value network_id)

vifs_eth1_network_id=${vifs_eth1_network_id:-nw-demo8}

sshkey_1box=${sshkey_1box:-~/centos.pem}
sshuser_1box=${sshuser_1box:centos}

## functions

function needs_vif() { true; }

function render_vif_table() {
  cat <<-EOS
	{
	"eth0":{"index":"0","network":"${vdc_network_uuid}","security_groups":""},
	"eth1":{"index":"1","network":"${vifs_eth1_network_id}","security_groups":""}
	}
	EOS
}

function ssh_1box_to_wait_for_network_to_be_ready() {
  local instance_ipaddr=$1
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${sshkey_1box} ${sshuser_1box}@${DCMGR_HOST} "
    while : ; do eval 'ping -c 1 -W 3 ${instance_ipaddr}' && break || { sleep ${sleep_sec} }; done
  "
}

### instance

function oneTimeSetUp() {
  # launching instances
  for i in $(eval echo "{1..${target_instance_num:-1}}"); do
    create_instance
    echo ${instance_uuid} >> ${instance_uuids_path}
  done

  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr="$(cached_instance_param ${instance_uuid} | grep -A 2 ${vifs_eth1_network_id} | hash_value address)"

    # wait until the instance be ready
    ssh_1box_to_wait_for_network_to_be_ready ${instance_ipaddr}
  done
}

function oneTimeTearDown() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    destroy_instance
  done
  rm -f ${instance_uuids_path}
}
