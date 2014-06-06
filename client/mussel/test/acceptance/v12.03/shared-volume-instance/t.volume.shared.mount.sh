#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
blank_volume_size=${blank_volume_size:-10}

## functions

## step

function test_mount_shared_volume(){
  # boot shared volume instance
  create_instance
 
  remote_sudo=$(remote_sudo)

  # create new volume
  volume_uuid=$(volume_size=${blank_volume_size} run_cmd volume create | hash_value uuid)
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # attch volume to instance
  instance_id=${instance_uuid} run_cmd volume attach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state attached"
  assertEquals 0 $?

  # work around
  sleep 30

  # blank device path 
  dev_name=$(find_dev_path)
  [[ -n "${dev_name}" ]]
  assertEquals 0 $?
  [[ -n "${dev_name}" ]] || return
  blank_dev_path=/dev/${dev_name}

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

  # terminate the instance.
  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?
}

function test_mount_shared_volume_halted_instance(){
  # boot shared volume instance
  create_instance

  remote_sudo=$(remote_sudo)

  # poweroff instance
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  # create new volume
  volume_uuid=$(volume_size=${blank_volume_size} run_cmd volume create | hash_value uuid)
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # attach volume to instance
  instance_id=${instance_uuid} run_cmd volume attach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state attached"
  assertEquals 0 $?

  # poweron instance
  run_cmd instance poweron ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?

  # wait for network to be ready
  wait_for_network_to_be_ready ${instance_ipaddr}

  # wait for sshd to be ready
  wait_for_sshd_to_be_ready    ${instance_ipaddr}

  # work around
  sleep 30

  # blank device path
  dev_name=$(find_dev_path)
  [[ -n "${dev_name}" ]]
  assertEquals 0 $?
  [[ -n "${dev_name}" ]] || return
  blank_dev_path=/dev/${dev_name}

  # device check
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

  # poweroff instance
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  # detach volume to instance
  instance_id=${instance_uuid} run_cmd volume detach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # poweron instance
  run_cmd instance poweron ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?

  # wait for network to be ready
  wait_for_network_to_be_ready ${instance_ipaddr}

  # wait for sshd to be ready
  wait_for_sshd_to_be_ready    ${instance_ipaddr}

  # device-check
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertNotEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?

  # terminate the instance.
  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}

