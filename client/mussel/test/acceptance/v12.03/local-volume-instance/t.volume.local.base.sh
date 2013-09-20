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

## functions

### step

function test_show_local_volume_info() {
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-'EOS'
	# for debug
	df -P -h
	lsblk
	EOS
  assertEquals 0 $?

  echo "> ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path}"
  interactive_suspend_test
}

## shunit2

. ${shunit2_file}
