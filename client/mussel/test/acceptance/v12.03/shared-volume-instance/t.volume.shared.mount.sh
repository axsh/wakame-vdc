#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
blank_volume_size=${blank_volume_size:-10M}

## functions

## step

# API test for mount shared volume.
#
# 1. boot shared volume instance.
# 2. create new volume.
# 3. attch volume to instance.
# 4. device check.
# 5. volume format.
# 6. volume mount.
# 7. check disk-usage.
# 8. volume umount.
# 9. detach volume to instance.
# 10. device check.
# 11. delete volume.
# 12. terminate the instance.
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

  # terminate the instance.
  destroy_instance
}

# API test for mount shared volume halted instance.
#
# 1. boot shared volume instance.
# 2. poweroff instance.
# 3. create new volume.
# 4. attch volume to instance.
# 5. poweron instance.
# 6. device check.
# 7. volume format.
# 8. volume mount.
# 9. check disk-usage.
# 10. poweroff instance.
# 11. detach volume to instance.
# 12. poweron instance.
# 13. device check.
# 14. delete volume.
# 15. terminate the instance.
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

  # TODO: temporarily using device /dev/sdc, /dev/vdc
  # blank device path
  blank_dev_path=$(blank_dev_path)
  [[ -n "${blank_dev_path}" ]]
  assertEquals 0 $?
  [[ -n "${blank_dev_path}" ]] || return

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
  destroy_instance
}

## shunit2
. ${shunit2_file}

