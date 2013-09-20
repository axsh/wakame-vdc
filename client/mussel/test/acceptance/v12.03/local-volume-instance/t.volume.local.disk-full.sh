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
  # should be root
  [[ "${ssh_user}" == "root" ]] || return 0

  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-'EOS'
	dev_path=
	[[ -b /dev/vdc ]] && dev_path=/dev/vdc || :
	[[ -b /dev/sdc ]] && dev_path=/dev/sdc || :
	[[ -n "${dev_path}" ]] || exit 1
	# mounted?
	mount ${dev_path} || { :; }  && { ! :; }
	# format
	mkfs.ext3 -F -I 128 ${dev_path}
	# mount
	mount ${dev_path} /mnt
	# disk-usage
	df -h
	echo ... use disk usage 100%
	time dd if=/dev/urandom of=/mnt/test.data
	echo $?
	# disk-usage
	df -h
	EOS
  assertEquals 0 $?

  echo "> ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path}"
  interactive_suspend_test
}

## shunit2

. ${shunit2_file}
