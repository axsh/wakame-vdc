#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

ssh_user=${ssh_user:-root}

## functions

function suites(){
  # kvm only
  [[ ${hypervisor} = 'kvm' ]] || return 0
  suite_addTest "test_force_poweroff_halting_instance"
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	EOS
}

### step

function test_force_poweroff_halting_instance() {

  # this test only work for kvm.
  [[ ${hypervisor} = 'kvm' ]] || return 0

  # wait for ready
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  assertEquals 0 $?

  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?

  wait_for_sshd_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?

  # stop acpid
  remove_ssh_known_host_entry ${instance_ipaddr}
  ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "/etc/init.d/acpid stop"
  assertEquals 0 $?

  # soft poweroff
  force=false run_cmd instance poweroff ${instance_uuid}
  assertEquals 0 $?

  retry_until "document_pair? instance ${instance_uuid} state halting"
  assertEquals 0 $?

  # retry soft poweroff and state still would be halting
  sleep 3
  retry_until "document_pair? instance ${instance_uuid} state halting"
  assertEquals 0 $?

  force=false run_cmd instance poweroff ${instance_uuid}
  assertEquals 0 $?

  retry_until "document_pair? instance ${instance_uuid} state halting"
  assertEquals 0 $?

  # force poweroff
  force=true run_cmd instance poweroff ${instance_uuid}
  assertEquals 0 $?

  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  wait_for_network_not_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?

  wait_for_sshd_not_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

# shunit2

. ${shunit2_file}
