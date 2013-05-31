#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/../../../helpers/interactive.sh

## variables

declare instance_ipaddr=
declare instance_uuids_path=$(generate_cache_file_path instance_uuids)

function needs_vif() { true; }
function needs_secg() { true; }

ssh_user=${ssh_user:-root}
image_id=${image_id_lbnode:-wmi-lbnode}
vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

api_client_addr=$(for i in $(ip route get ${DCMGR_HOST} | head -1); do echo ${i}; done | tail -1)

target_instance_num=${target_instance_num:-5}

cat <<-EOS > ${rule_path}
icmp:-1,-1,ip4:${api_client_addr}/32
tcp:22,22,ip4:${api_client_addr}/32
EOS
rule=${rule_path}

security_group_default=
security_group_aaa=
security_group_bbb=

empty_security_group_uuid=
ssh_and_icmp_security_group_uuid=

## functions

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":["${empty_security_group_uuid_1}","${empty_security_group_uuid_2}","${security_group_default}"]}}
	EOS
}

function before_create_instance() {
  # don't clear ssh_key_pair_uuid= to apply same keypair to instances
  instance_uuid=
}

function oneTimeSetUp() {
  security_group_default=$(run_cmd security_group create | hash_value id)
  security_group_aaa=$(run_cmd security_group create | hash_value id)
  security_group_bbb=$(run_cmd security_group create | hash_value id)

  # create
  for i in $(eval echo "{1..2}"); do
    empty_security_group_uuid_1=$(display_name="empty${i}_1" run_cmd security_group create | hash_value id)
    empty_security_group_uuid_2=$(display_name="empty${i}_2" run_cmd security_group create | hash_value id)
    create_instance
    echo ${instance_uuid} >> ${instance_uuids_path}
    echo "$(cached_instance_param ${instance_uuid})"
  done

  # wait
  for instance_uuid in $(cat ${instance_uuids_path}); do
    local instance_ipaddr="$(cached_instance_param ${instance_uuid} | hash_value address)"
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

  run_cmd security_group index | grep ':id:' | awk '{print $3}' | while read security_group_id; do
    echo ${security_group_id}
    run_cmd security_group destroy ${security_group_id}
  done

  run_cmd ssh_key_pair index | grep ':id:' | awk '{print $3}' | while read ssh_key_pair_id; do
    echo ${ssh_key_pair_id}
    run_cmd ssh_key_pair destroy ${ssh_key_pair_id}
  done
}

### step

function test_complex_security_group() {

  local instance_uuids=()
  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_uuids+=($instance_uuid)
  done

  # aaa_1
  local instance_aaa_1=${instance_uuids[0]}
  local vif_aaa_1="$(cached_instance_param ${instance_aaa_1} | hash_value vif_id)"
  local ipaddr_aaa_1="$(cached_instance_param ${instance_aaa_1} | hash_value address)"

  # aaa_2
  local instance_aaa_2=${instance_uuids[1]}
  local vif_aaa_2="$(cached_instance_param ${instance_aaa_2} | hash_value vif_id)"
  local ipaddr_aaa_2="$(cached_instance_param ${instance_aaa_2} | hash_value address)"

  echo setup finished
  interactive_suspend_test

  security_group_id=${security_group_aaa} run_cmd network_vif add_security_group ${vif_aaa_1}
  security_group_id=${security_group_default} run_cmd network_vif remove_security_group ${vif_aaa_1} 

  # from aaa_1
  ssh ${ssh_user}@${ipaddr_aaa_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_2}"
  assertNotEquals "aaa_1 -> aaa_2" $? 0

  # from aaa_2
  ssh ${ssh_user}@${ipaddr_aaa_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_1}"
  assertNotEquals "aaa_2 -> aaa_1" $? 0
}

## shunit2

. ${shunit2_file}
