#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

target_instance_num=2

## functions

function test_vnet() {
  opts="-o stricthostkeychecking=no -o userknownhostsfile=/dev/null"

  scp -i ${sshkey_1box} ${opts} ${ssh_key_pair_path} ${sshuser_1box}@${DCMGR_HOST}:~

  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr_vnet=$(cached_instance_param ${instance_uuid} | grep -A 2 "${vdc_network_uuid}" | hash_value address)
    instance_ipaddr_mng=$(cached_instance_param ${instance_uuid} | grep -A 2 "${vifs_eth1_network_id}" | hash_value address)

    echo "instance_ipaddr_vnet : ${instance_ipaddr_vnet}"
    echo "instance_ipaddr_mng  : ${instance_ipaddr_mng}"
    echo "ssh_key_pair         : ${ssh_key_pair_path##*/}"

    for peer_instance_uuid in $(cat ${instance_uuids_path}); do
      peer_instance_ipaddr_vnet=$(cached_instance_param ${peer_instance_uuid} | grep -A 2 "${vdc_network_uuid}" | hash_value address)
      [[ ${peer_instance_ipaddr_vnet} == ${instance_ipaddr_vnet} ]] && continue

      echo "peer_instance_ipaddr_vnet : ${peer_instance_ipaddr_vnet}"

      ssh ${opts} -i ${sshkey_1box} ${sshuser_1box}@${DCMGR_HOST} "
        ssh ${opts} -i ${ssh_key_pair_path##*/} root@${instance_ipaddr_mng} \"ping -c 1 -W 3 ${peer_instance_ipaddr_vnet}\"
      "
      assertEquals 0 $?
    done
  done
}

## shunit2

. ${shunit2_file}
