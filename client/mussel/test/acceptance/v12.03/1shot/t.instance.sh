#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare wait_sec=120
declare ssh_keypair_path=${BASH_SOURCE[0]%/*}/keypair.$$
declare rule_path=${BASH_SOURCE[0]%/*}/rule.$$
declare vifs_path=${BASH_SOURCE[0]%/*}/vifs.$$

# configuarable variables

image_id=${image_id:-wmi-centos1d}
hypervisor=${hypervisor:-openvz}
cpu_cores=${cpu_cores:-1}
memory_size=${memory_size:-256}
network_id=${network_id:-nw-demo1}

# test local variables

declare inst_id=
declare inst_hash=
declareipaddr=

## functions

function oneTimeTearDown() {
  rm -f ${ssh_keypair_path}*
  rm -f ${vifs_path}
  rm -f ${rule_path}
}

function login_to() {
  local host=$1; shift

  $(which ssh) ${host} -i ${ssh_keypair_path} -o 'StrictHostKeyChecking no' $@
}

function check_port() {
  local ipaddr=$1 protocol=$2 port=$3

  local nc_opts="-w 1"
  case ${protocol} in
  tcp) ;;
  udp) nc_opts="${nc_opts} -u";;
    *) ;;
  esac

  echo | nc ${nc_opts} ${ipaddr} ${port} >/dev/null
}

function check_network_connection() {
  local ipaddr=$1

  ping -c 1 -W 1 ${ipaddr}
}

### step

function test_generate_ssh_key_pair() {
  ssh-keygen -N "" -f ${ssh_keypair_path} -C shunit2.$$ >/dev/null
  assertEquals $? 0
}

function test_create_ssh_key_pair() {
  public_key=${ssh_keypair_path}.pub

  ssh_key_id=$(run_cmd ssh_key_pair create | hash_value id)
  assertEquals $? 0
}

function test_create_security_group() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
  rule=${rule_path}

  secg_id=$(run_cmd security_group create | hash_value id)
  assertEquals $? 0
}

function test_create_instance() {
  cat <<-EOS > ${vifs_path}
	{"eth0":{"index":"0","network":"${network_id}","security_groups":"${secg_id}"}}
	EOS
  vifs=${vifs_path}

  inst_id=$(run_cmd instance create | hash_value id)
  assertEquals $? 0
}

function test_wait_for_instance_state_is_running() {
  retry_until ${wait_sec} "check_document_pair instance ${inst_id} state running"
  assertEquals $? 0
}

function test_get_instance_hash(){
  inst_hash="$(run_cmd instance show ${inst_id})"
  assertEquals $? 0
}

function test_get_instance_ipaddr() {
  ipaddr=$(echo "${inst_hash}" | hash_value address)
  assertEquals $? 0
}

function test_wait_for_instance_network_is_ready() {
  retry_until ${wait_sec} "check_network_connection ${ipaddr}" >/dev/null
  assertEquals $? 0
}

function test_wait_for_instance_sshd_is_ready() {
  retry_until ${wait_sec} "check_port ${ipaddr} tcp 22" >/dev/null
  assertEquals $? 0
}

function test_remove_ssh_known_host_entry() {
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
  assertEquals $? 0
}

function test_compare_instance_hostname() {
  assertEquals \
    "$(echo "${inst_hash}" | hash_value hostname)" \
    "$(login_to root@${ipaddr} hostname)"
}

function test_compare_instance_ipaddr() {
  login_to root@${ipaddr} ip addr show eth0 | egrep -q ${ipaddr}
  assertEquals $? 0
}

function test_destroy_instance() {
  run_cmd instance destroy ${inst_id} >/dev/null
  assertEquals $? 0
}

function test_wait_for_instance_state_is_terminated() {
  retry_until ${wait_sec} "check_document_pair instance ${inst_id} state terminated"
  assertEquals $? 0
}

function test_destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_id} >/dev/null
  assertEquals $? 0
}

function test_destroy_security_group() {
  run_cmd security_group destroy ${secg_id} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
