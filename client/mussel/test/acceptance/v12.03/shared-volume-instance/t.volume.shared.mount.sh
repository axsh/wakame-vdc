#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
volume_size=${volume_size:-10}

## functions

## step

function test_mount_shared_volume(){
  remote_sudo=$(remote_sudo)

  # create new volume
  volume_uuid=$(volume_size=${volume_size} run_cmd volume create | hash_value uuid)
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # attch volume to instance
  instance_id=${instance_uuid} run_cmd volume attach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state attached"
  assertEquals 0 $?

  # TODO: temporarily using device /dev/sdc, /dev/vdc
  # blank device path 
  blank_dev_path=$(blank_dev_path)
  [[ -n "${blank_dev_path}" ]]
  assertEquals 0 $?
  [[ -n "${blank_dev_path}" ]] || return

  # device-check
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # format
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} mkfs.ext3 -F -I 128 ${blank_dev_path}
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

  # umount
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} umount /mnt
	EOS
  assertEquals 0 $?

  # detach volume to instance
  instance_id=${instance_uuid} run_cmd volume detach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # device-check
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertNotEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}

