#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare ssh_keypair_path=${BASH_SOURCE[0]%/*}/keypair.$$
declare rule_path=${BASH_SOURCE[0]%/*}/rule.$$
declare vifs_path=${BASH_SOURCE[0]%/*}/vifs.$$

## functions

function setUp() {
  # ssh_key_pair
  ssh-keygen -N "" -f ${ssh_keypair_path} -C shunit2.$$ >/dev/null
  public_key=${ssh_keypair_path}.pub
  ssh_key_id=$(run_cmd ssh_key_pair create | hash_value id)

  # security_group
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
  rule=${rule_path}
  secg_id=$(run_cmd security_group create | hash_value id)

  # configuarable variables
  image_id=${image_id:-wmi-centos1d}
  hypervisor=${hypervisor:-openvz}
  cpu_cores=${cpu_cores:-1}
  memory_size=${memory_size:-256}
  network_id=${network_id:-nw-demo1}

  cat <<-EOS > ${vifs_path}
	{"eth0":{"index":"0","network":"${network_id}","security_groups":"${secg_id}"}}
	EOS
  vifs=${vifs_path}
}

function tearDown() {
  run_cmd ssh_key_pair   destroy ${ssh_key_id}
  run_cmd security_group destroy ${secg_id}

  rm -f ${ssh_keypair_path}*
  rm -f ${vifs_path}
  rm -f ${rule_path}
}

### step

function test_1shot() {
  local inst_id

  inst_id=$(run_cmd instance create | hash_value id)
  assertEquals $? 0

  retry_until 120 "check_document_pair instance ${inst_id} state running"
  sleep 1

  run_cmd instance show ${inst_id}
  ipaddr=$(run_cmd instance show ${inst_id} | hash_value address)

  retry_until 120 "ping -c 1 -W 1 ${ipaddr}"
  retry_until 120 "(echo | nc -w 1 ${ipaddr} 22)"

  ssh-keygen -R ${ipaddr} >/dev/null
  sleep 1

  run_cmd instance destroy ${inst_id}
  assertEquals $? 0

  retry_until 120 "check_document_pair instance ${inst_id} state terminated"
}

## shunit2

. ${shunit2_file}
