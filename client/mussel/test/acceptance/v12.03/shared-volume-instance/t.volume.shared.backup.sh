#!/bin/bash
#
#
#

## include files
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
blank_volume_size=${blank_volume_size:-10}

## functions
last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})

  # reset command parameters
  volumes_args=
}

## step

# API test for image backup just for boot volume.
#
# 1. boot shared volume instance.
# 2. poweroff the instance.
# 3. instance backup.
# 4. assert that poweron should fail until backup task completes.
# 5. confirm that the instance from backup image accepts ssh login.
# 6. terminate the instance from backup.
# 7. delete image.
# 8. delete backup object.
# 9. terminate the instance.
function test_image_backup_just_for_boot_volume() {
  # boot instance with second blank volume.
  volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=shared"

  # boot shared volume instance
  create_instance

  local instance_uuid1=${instance_uuid}

  # poweroff instance
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "${volume_uuid}"
  assertEquals 0 $?

  # instance backup
  run_cmd instance backup ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local image_uuid=$(yfind ':image_id:' < $last_result_path)
  test -n "${image_uuid}"
  assertEquals 0 $?

  run_cmd image show ${image_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local backup_object_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "${backup_object_uuid}"
  assertEquals 0 $?

  # assert that poweron should fail until backup task completes.
  run_cmd instance poweron ${instance_uuid} >/dev/null
  assertNotEquals 0 $?

  retry_until "document_pair? image ${image_uuid} state available"
  assertEquals 0 $?

  # confirm that the instance from backup image accepts ssh login.
  local image_id=${image_uuid}
  create_instance

  remote_sudo=$(remote_sudo)
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk
	EOS
  assertEquals 0 $?

  # terminate the instance from backup.
  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?

  # delete image
  run_cmd image destroy ${image_uuid}
  assertEquals 0 $?

  # delete backup object
  run_cmd backup_object destroy ${backup_object_uuid}
  assertEquals 0 $?

  # terminate the instance.
  local instance_uuid=${instance_uuid1}
  destroy_instance
}

# API test for image backup just for boot volume and second blank volume
#
# 1. boot shared volume instance.
# 2. poweroff instance.
# 3. backup instance and second blank volume.
# 4. assert that poweron should fail until backup task completes.
# 5. confirm that the instance from backup image accepts ssh login.
# 6. terminate the instance from backup.
# 7. delete image.
# 8. delete backup object from boot volume.
# 9. delete backup object from second blank volume.
# 10. delete terminate the instance.
function test_image_backup_just_for_boot_volume_and_second_blank_volume() {
  # boot instance with second blank volume.
  volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=shared"

  # boot shared volume instance
  create_instance

  local instance_uuid1=${instance_uuid}

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "{$volume_uuid}"
  assertEquals 0 $?

  remote_sudo=$(remote_sudo)

  # blank device path
  blank_dev_path=$(blank_dev_path)
  test -n "${blank_dev_path}"
  assertEquals 0 $?
  test -n "${blank_dev_path}" | return

  # device check
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # format
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} mkfs.ext3 -F -I 128 ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # mount
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} mount ${blank_dev_path} /mnt
	EOS
  assertEquals 0 $?
 
  # disk usage
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # touch file
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} touch /mnt/sample.txt
	EOS
  assertEquals 0 $?

  # umount
  ssh -t  ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} umount /mnt
	EOS
  assertEquals 0 $?

  # poweroff instance
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  # instance backup
  all=true run_cmd instance backup ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local image_uuid=$(yfind ':image_id:' < $last_result_path)
  test -n "$image_uuid"
  assertEquals 0 $?

  run_cmd image show ${image_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local backup_object_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_object_uuid"
  assertEquals 0 $?

  local volume_backup_object_uuid=$(yfind ':volumes:/0/:backup_object_id:' < $last_result_path)
  test -n "$backup_object_uuid"
  assertEquals 0 $?

  # assert that poweron should fail until backup task completes.
  run_cmd instance poweron ${instance_uuid} >/dev/null
  assertNotEquals 0 $?

  retry_until "document_pair? image ${image_uuid} state available"
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${volume_backup_object_uuid} state available"
  assertEquals 0 $?

  # confirm that the instance from backup image accepts ssh login.
  local image_id=${image_uuid}
  local volumes_args=
  create_instance

  remote_sudo=$(remote_sudo)
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk
	EOS
  assertEquals 0 $?
 
  # terminate the instance from backup.
  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?

  # delete image
  run_cmd image destroy ${image_uuid}
  assertEquals 0 $?

  # delete backup object
  run_cmd backup_object destroy ${backup_object_uuid}
  assertEquals 0 $?

  # delete backup object
  run_cmd backup_object destroy ${volume_backup_object_uuid}
  assertEquals 0 $?

  # terminate the instance.
  local instance_uuid=${instance_uuid1}
  destroy_instance
}

# API test for volume backup second blank volume.
#
# 1. boot shared volume instance.
# 2. poweroff instance.
# 3. backup second blank volume.
# 4. assert that poweron should fail until backup task completes.
# 5. delete backup object from second blank volume.
# 6. terminate the instance.
function test_volume_backup_second_blank_volume(){
  # boot instance with second blank volume.
  volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=shared"

  # boot shared volume instance
  create_instance

  # poweroff instance
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local ex_volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "$ex_volume_uuid"
  assertEquals 0 $?

  # backup second blank volume
  run_cmd instance backup_volume ${instance_uuid} $ex_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?

  local backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid"
  assertEquals 0 $?

  # assert that poweron should fail until backup task completes.
  run_cmd instance poweron ${instance_uuid} >/dev/null
  assertNotEquals 0 $?

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
  assertEquals 0 $?

  # delete backup_object
  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  # terminate the instance.
  destroy_instance
}

## shunit2
. ${shunit2_file}

