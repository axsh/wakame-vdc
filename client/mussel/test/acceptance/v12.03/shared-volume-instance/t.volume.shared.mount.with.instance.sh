#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
blank_volume_size=${blank_volume_size:-10M}

## function
last_result_path=""

function setUp(){
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})

  # reset command parameters
  volumes_args=
}

## instance
function before_create_instance() {
  # boot instance with second blank volume.
  volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=shared"
}

## step

# API test for mount shared volume with instance.
#
# 1. boot shared volume instance.
# 2. device check.
# 3. format.
# 4. mount.
# 5. disk usage.
# 6. umount.
# 7. terminate the instance.
function test_mount_shared_volume_with_instance(){
  # boot shared volume instance.
  create_instance

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "${volume_uuid}"
  assertEquals 0 $?
  echo "volume uuid: ${volume_uuid}"

  remote_sudo=$(remote_sudo)

  # blank dev path
  blank_dev_path=$(blank_dev_path)
  test -n "${blank_dev_path}"
  assertEquals 0 $?
  test -n "${blank_dev_path}" || return
  echo "dev path: ${blank_dev_path}"

  # work around: lsblk
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk
	EOS
  assertEquals 0 $?

  # device check  
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
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

  # disk usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # umount
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} umount /mnt
	EOS
  assertEquals 0 $?

  # terminate the instance
  destroy_instance
}


# Test that the volume can exchange between two RUNNING instances.
#
# 1. boot shared volume instance "instance_uuid1" with extra blank volume.
# 2. boot shared volume instance "instance_uuid2" without extra volume.
# 3. detach volume from instance_uuid1
# 4. attach volume to instance_uuid2
# 7. terminate instance_uuid1 & instance_uuid2.
function test_exchange_shared_volume_between_two_running_instances(){
  # boot instance with second blank volume.
  volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=shared"

  # boot shared volume instance "instance_uuid1" with extra blank volume.
  create_instance

  local instance_uuid1=${instance_uuid}

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "{$volume_uuid}"
  assertEquals 0 $?

  echo "instance_uuid1=${instace_uuid1}, extra volume uuid=${volume_uuid}"

  # boot shared volume instance "instance_uuid2" without extra volume.
  volumes_args=""
  create_instance

  local instance_uuid2=${instance_uuid}

  echo "instance_uuid2=${instace_uuid2}"

  # detach volume from instance_uuid1
  instance_id=${instance_uuid1} run_cmd volume detach "${volume_uuid}"
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # attach volume to instance_uuid2
  instance_id=${instance_uuid2} run_cmd volume attach "${volume_uuid}"
  retry_until "document_pair? volume ${volume_uuid} state attached"
  assertEquals 0 $?

  # terminate instance_uuid1 & instance_uuid2.
  local instance_uuid=${instance_uuid1}
  destroy_instance
  local instance_uuid=${instance_uuid2}
  destroy_instance

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}

