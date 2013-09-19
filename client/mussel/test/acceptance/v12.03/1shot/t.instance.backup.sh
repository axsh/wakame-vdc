#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

description=${description:-}
display_name=${display_name:-}
is_cacheable=${is_cacheable:-}
is_public=${is_public:-}

## hook functions

last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})
}

### step

# API test for second volume backup.
#
# 1. boot instance with second blank volume.
# 2. poweroff the instance.
# 3. backup the second volume.
# 4. shutdown everything.
function test_backup_second_blank_volume() {
  # boot instance with second blank volume.
  if is_container_hypervisor; then
    volumes_args="volumes[0][size]=1G volumes[0][volume_type]=local volumes[0][guest_device_name]=/mnt/tmp"
  else
    volumes_args="volumes[0][size]=1G volumes[0][volume_type]=local"
  fi
  create_instance

  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local ex_volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "$ex_volume_uuid"
  assertEquals 0 $?

  run_cmd instance backup_volume ${instance_uuid} $ex_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?

  local backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid"
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"

  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?
}

# API test for second volume backup.
#
# 1. boot instance with second volume from backup.
# 2. poweroff the instance.
# 3. backup the second volume.
# 4. shutdown everything.
function test_backup_second_volume_from_backup() {
  run_cmd image show ${image_id} | ydump > $last_result_path
  local backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)

  # boot instance with second blank volume.
  if is_container_hypervisor; then
    volumes_args="volumes[0][backup_object_id]=${backup_obj_uuid} volumes[0][volume_type]=local volumes[0][guest_device_name]=/mnt/tmp"
  else
    volumes_args="volumes[0][backup_object_id]=${backup_obj_uuid} volumes[0][volume_type]=local"
  fi
  create_instance

  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local ex_volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "$ex_volume_uuid"
  assertEquals 0 $?

  run_cmd instance backup_volume ${instance_uuid} $ex_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?

  backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid"
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"

  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?
}

# API test for image backup.
#
# 1. boot instance with second blank volume.
# 2. poweroff the instance.
# 3. take backup of OS image.
# 4. shutdown everything.
function test_backup_second_blank_volume() {
  # boot instance with second blank volume.
  if is_container_hypervisor; then
    volumes_args="volumes[0][size]=1G volumes[0][volume_type]=local volumes[0][guest_device_name]=/mnt/tmp"
  else
    volumes_args="volumes[0][size]=1G volumes[0][volume_type]=local"
  fi
  create_instance

  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"

  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local ex_volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "$ex_volume_uuid"
  assertEquals 0 $?

  run_cmd instance backup ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local image_uuid=$(yfind ':image_id:' < $last_result_path)
  test -n "$image_uuid"
  assertEquals 0 $?

  local backup_object_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_object_uuid"
  assertEquals 0 $?

  retry_until "document_pair? image ${image_uuid} state available"

  run_cmd image destroy ${image_uuid}
  assertEquals 0 $?

  run_cmd instance destroy ${instance_uuid} >/dev/null
  assertEquals 0 $?
}



## shunit2

. ${shunit2_file}
