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

api_client_addr=$(for i in $(/sbin/ip route get ${DCMGR_HOST} | head -1); do echo ${i}; done | tail -1)

target_instance_num=${target_instance_num:-5}

rule=${rule_path}

security_group_default=
security_group_aaa=

ssh_and_icmp_security_group_uuid=

## functions

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":["${security_group_default}"]}}
	EOS
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:${api_client_addr}/32
	tcp:22,22,ip4:${api_client_addr}/32
	EOS
}

function render_ssh_and_icmp_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:${api_client_addr}/32
	tcp:22,22,ip4:${api_client_addr}/32
	EOS
}

function render_empty_secg_rule() {
	:
}

function before_create_instance() {
  # don't clear ssh_key_pair_uuid= to apply same keypair to instances
  instance_uuid=
}

function oneTimeSetUp() {
  security_group_default=$(rule="#" display_name="default" run_cmd security_group create | hash_value id)
  security_group_aaa=$(rule="#" display_name="aaa" run_cmd security_group create | hash_value id)

  # create
  for i in $(eval echo "{1..3}"); do
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
#    wait_for_network_to_be_ready ${instance_ipaddr}
#    wait_for_sshd_to_be_ready    ${instance_ipaddr}
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

  # xxx
  local instance_xxx=${instance_uuids[0]}
  local vif_xxx="$(cached_instance_param ${instance_xxx} | hash_value vif_id)"
  local ipaddr_xxx="$(cached_instance_param ${instance_xxx} | hash_value address)"

  # yyy
  local instance_yyy=${instance_uuids[1]}
  local vif_yyy="$(cached_instance_param ${instance_yyy} | hash_value vif_id)"
  local ipaddr_yyy="$(cached_instance_param ${instance_yyy} | hash_value address)"

  # zzz
  local instance_zzz=${instance_uuids[2]}
  local vif_zzz="$(cached_instance_param ${instance_zzz} | hash_value vif_id)"
  local ipaddr_zzz="$(cached_instance_param ${instance_zzz} | hash_value address)"

  echo ====================
  echo xxx:
  echo $instance_xxx
  echo $vif_xxx
  echo $ipaddr_xxx
  echo ====================
  echo ====================
  echo yyy:
  echo $instance_yyy
  echo $vif_yyy
  echo $ipaddr_yyy
  echo ====================
  echo ====================
  echo zzz:
  echo $instance_zzz
  echo $vif_zzz
  echo $ipaddr_zzz
  echo ====================
    echo security_group_default: ${security_group_default}
    echo security_group_aaa: ${security_group_aaa}
  echo

  echo setup finished
  echo please check iptables dump
  interactive_suspend_test

  # update security group
  # add security group
  render_empty_secg_rule > ${rule_path}
  service_type=std description= display_name= run_cmd security_group update ${security_group_aaa}

  security_group_id=${security_group_aaa} run_cmd network_vif add_security_group ${vif_xxx}

  echo please check iptables dump
  interactive_suspend_test

  # update security group
  # add security group
  render_empty_secg_rule > ${rule_path}
  service_type=std description= display_name= run_cmd security_group update ${security_group_aaa}

  security_group_id=${security_group_aaa} run_cmd network_vif add_security_group ${vif_yyy}

  echo please check iptables dump
  interactive_suspend_test

  # update security group
  # remove security group
  render_secg_rule > ${rule_path}
  service_type=std description= display_name= run_cmd security_group update ${security_group_default}

  security_group_id=${security_group_default} run_cmd network_vif remove_security_group ${vif_xxx}
  security_group_id=${security_group_default} run_cmd network_vif remove_security_group ${vif_yyy}

  echo please check iptables dump
  interactive_suspend_test

  # from xxx
  ssh ${ssh_user}@${ipaddr_xxx} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_yyy}"
  assertNotEquals "xxx -> yyy" $? 0

  # from yyy
  ssh ${ssh_user}@${ipaddr_yyy} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${ipaddr_xxx}"
  assertNotEquals "yyy -> xxx" $? 0
}

## shunit2

. ${shunit2_file}
