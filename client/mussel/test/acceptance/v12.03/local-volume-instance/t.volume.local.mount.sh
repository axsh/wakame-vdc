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

function test_mount_local_volume() {
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-'EOS'
	case "${UID}" in
	0) sudo=     ;;
	*) sudo=sudo ;;
	esac
	#
	dev_path=
	[[ -b /dev/vdc ]] && dev_path=/dev/vdc || :
	[[ -b /dev/sdc ]] && dev_path=/dev/sdc || :
	[[ -n "${dev_path}" ]] || exit 1
	# mounted?
	mount ${dev_path} || { :; }  && { ! :; }
	# format
	${sudo} mkfs.ext3 -F -I 128 ${dev_path}
	# mount
	${sudo} mount ${dev_path} /mnt
	# disk-usage
	df -P -h
	EOS
  assertEquals 0 $?

  echo "> ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path}"
  interactive_suspend_test
}

## shunit2

. ${shunit2_file}
