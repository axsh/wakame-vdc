#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare instance_ipaddr=
declare instance_uuids_path=$(generate_cache_file_path instance_uuids)

function needs_vif() { true; }
function needs_secg() { true; }

ssh_user=${ssh_user:-root}
image_id=${image_id_lbnode:-wmi-lbnode}
vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

api_client_addr=${DCMGR_CLIENT_ADDR:-$(for i in $(/sbin/ip route get ${DCMGR_HOST} | head -1); do echo ${i}; done | tail -1)}

target_instance_num=${target_instance_num:-5}

rule=${rule_path}

security_group_default=
security_group_aaa=
security_group_bbb=

empty_security_group_uuid=
ssh_and_icmp_security_group_uuid=

## functions

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":["${empty_security_group_uuid}","${security_group_default}"]}}
	EOS
}

function render_ssh_and_icmp_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:${api_client_addr}/32
	tcp:22,22,ip4:${api_client_addr}/32
	EOS
}

function before_create_instance() {
  # don't clear ssh_key_pair_uuid= to apply same keypair to instances
  instance_uuid=
}

function oneTimeSetUp() {
  security_group_default=$(rule="#" display_name="default" run_cmd security_group create | hash_value id)
  security_group_aaa=$(rule="#" display_name="aaa" run_cmd security_group create | hash_value id)
  security_group_bbb=$(rule="#" display_name="bbb" run_cmd security_group create | hash_value id)

  # create
  for i in $(eval echo "{1..5}"); do
    empty_security_group_uuid=$(rule="#" display_name="empty${i}" run_cmd security_group create | hash_value id)
    create_instance
    echo ${instance_uuid} >> ${instance_uuids_path}
    echo "$(cached_instance_param ${instance_uuid})"
  done

  # wait
  for instance_uuid in $(cat ${instance_uuids_path}); do
    render_ssh_and_icmp_secg_rule > ${rule_path}
    ssh_and_icmp_security_group_uuid=$(display_name="ssh-${instance_uuid}" run_cmd security_group create | hash_value id)
    local vif_id="$(cached_instance_param ${instance_uuid} | hash_value vif_id)"
    security_group_id=${ssh_and_icmp_security_group_uuid} run_cmd network_vif add_security_group ${vif_id}
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

  # bbb_1
  local instance_bbb_1=${instance_uuids[2]}
  local vif_bbb_1="$(cached_instance_param ${instance_bbb_1} | hash_value vif_id)"
  local ipaddr_bbb_1="$(cached_instance_param ${instance_bbb_1} | hash_value address)"

  # ccc_1
  local instance_ccc_1=${instance_uuids[3]}
  local vif_ccc_1="$(cached_instance_param ${instance_ccc_1} | hash_value vif_id)"
  local ipaddr_ccc_1="$(cached_instance_param ${instance_ccc_1} | hash_value address)"

  # ccc_2
  local instance_ccc_2=${instance_uuids[4]}
  local vif_ccc_2="$(cached_instance_param ${instance_ccc_2} | hash_value vif_id)"
  local ipaddr_ccc_2="$(cached_instance_param ${instance_ccc_2} | hash_value address)"

  echo ====================
  echo aaa_1:
  echo $instance_aaa_1
  echo $vif_aaa_1
  echo $ipaddr_aaa_1
  echo ====================
  echo aaa_2: $instance_aaa_2
  echo $instance_aaa_2
  echo $vif_aaa_2
  echo $ipaddr_aaa_2
  echo ====================
  echo bbb_1: $instance_bbb_1
  echo $instance_bbb_1
  echo $vif_bbb_1
  echo $ipaddr_bbb_1
  echo ====================
  echo ccc_1: $instance_ccc_1
  echo $instance_ccc_1
  echo $vif_ccc_1
  echo $ipaddr_ccc_1
  echo ====================
  echo ccc_2: $instance_ccc_2
  echo $instance_ccc_2
  echo $vif_ccc_2
  echo $ipaddr_ccc_2
  echo ====================
    echo security_group_default: ${security_group_default}
    echo security_group_aaa: ${security_group_aaa}
    echo security_group_bbb: ${security_group_bbb}
  echo

  echo setup finished
  interactive_suspend_test

  security_group_id=${security_group_aaa} run_cmd network_vif add_security_group ${vif_aaa_1}
  security_group_id=${security_group_aaa} run_cmd network_vif add_security_group ${vif_aaa_2}

  interactive_suspend_test

  security_group_id=${security_group_bbb} run_cmd network_vif add_security_group ${vif_bbb_1}

  interactive_suspend_test

  security_group_id=${security_group_default} run_cmd network_vif remove_security_group ${vif_aaa_1} 
  security_group_id=${security_group_default} run_cmd network_vif remove_security_group ${vif_aaa_2} 
  security_group_id=${security_group_default} run_cmd network_vif remove_security_group ${vif_bbb_1}

  # from aaa_1
  ssh ${ssh_user}@${ipaddr_aaa_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_2}"
  assertEquals "aaa_1 -> aaa_2" $? 0
  ssh ${ssh_user}@${ipaddr_aaa_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_bbb_1}"
  assertNotEquals "aaa_1 -> bbb_1" $? 0
  ssh ${ssh_user}@${ipaddr_aaa_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_1}"
  assertNotEquals "aaa_1 -> ccc_1" $? 0
  ssh ${ssh_user}@${ipaddr_aaa_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_2}"
  assertNotEquals "aaa_1 -> ccc_2" $? 0

  # from aaa_2
  ssh ${ssh_user}@${ipaddr_aaa_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_1}"
  assertEquals "aaa_2 -> aaa_1" $? 0
  ssh ${ssh_user}@${ipaddr_aaa_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_bbb_1}"
  assertNotEquals "aaa_2 -> bbb_1" $? 0
  ssh ${ssh_user}@${ipaddr_aaa_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_1}"
  assertNotEquals "aaa_2 -> ccc_1" $? 0
  ssh ${ssh_user}@${ipaddr_aaa_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_2}"
  assertNotEquals "aaa_2 -> ccc_2" $? 0

  # from bbb_1
  ssh ${ssh_user}@${ipaddr_bbb_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_1}"
  assertNotEquals "bbb_1 -> aaa_1" $? 0
  ssh ${ssh_user}@${ipaddr_bbb_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_2}"
  assertNotEquals "bbb_1 -> aaa_2" $? 0
  ssh ${ssh_user}@${ipaddr_bbb_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_1}"
  assertNotEquals "bbb_1 -> ccc_1" $? 0
  ssh ${ssh_user}@${ipaddr_bbb_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_2}"
  assertNotEquals "bbb_1 -> ccc_2" $? 0

  # from ccc_1
  ssh ${ssh_user}@${ipaddr_ccc_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_1}"
  assertNotEquals "ccc_1 -> aaa_1" $? 0
  ssh ${ssh_user}@${ipaddr_ccc_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_2}"
  assertNotEquals "ccc_1 -> aaa_2" $? 0
  ssh ${ssh_user}@${ipaddr_ccc_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_bbb_1}"
  assertNotEquals "ccc_1 -> bbb_1" $? 0
  ssh ${ssh_user}@${ipaddr_ccc_1} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_2}"
  assertEquals "ccc_1 -> ccc_2" $? 0

  # from ccc_2
  ssh ${ssh_user}@${ipaddr_ccc_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_1}"
  assertNotEquals "ccc_2 -> aaa_1" $? 0
  ssh ${ssh_user}@${ipaddr_ccc_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_aaa_2}"
  assertNotEquals "ccc_2 -> aaa_2" $? 0
  ssh ${ssh_user}@${ipaddr_ccc_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_bbb_1}"
  assertNotEquals "ccc_2 -> bbb_1" $? 0
  ssh ${ssh_user}@${ipaddr_ccc_2} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_ccc_1}"
  assertEquals "ccc_2 -> ccc_1" $? 0
}

## shunit2

. ${shunit2_file}
