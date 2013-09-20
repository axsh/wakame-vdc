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

function test_local_volume_disk_full() {
  remote_sudo=$(remote_sudo)

  # blank device path
  blank_dev_path=$(blank_dev_path)
  [[ -n "${blank_dev_path}" ]]
  assertEquals 0 $?
  [[ -n "${blank_dev_path}" ]] || return

  # format
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	time ${remote_sudo} mkfs.ext3 -F -I 128 ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # mount
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} mount ${blank_dev_path} /mnt
	EOS
  assertEquals 0 $?

  # disk-usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # disk-full
  # dd command will be failed after filling random data
  echo ... use disk usage 100%
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	time ${remote_sudo} dd if=/dev/urandom of=/mnt/test.data
	EOS
  assertNotEquals 0 $?

  # disk-usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # umount
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} umount /mnt
	EOS
  assertEquals 0 $?

  # disk-usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # debug
  echo "> ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path}"
  interactive_suspend_test
}

## shunit2

. ${shunit2_file}
