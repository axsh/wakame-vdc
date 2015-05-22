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

description=${description:-}
display_name=${display_name:-}
is_cacheable=${is_cacheable:-}
is_public=${is_public:-}

## hook functions

function after_create_instance() {
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
}

last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})
}

### step

# GET $base_uri/instances/i-xxxxx/volumes
function test_get_volume() {
  run_cmd instance show_volumes "${instance_uuid}" > /dev/null
  assertEquals 0 $?
}

# PUT $base_uri/instances/i-xxxxx/volumes/vol-xxxxxx/backup
function test_volume_backup_under_instances() {
  run_cmd instance show_volumes "${instance_uuid}"| ydump > $last_result_path
  assertEquals 0 $?
  
  local boot_volume_uuid=$(yfind '0/:uuid:' < $last_result_path)
  test -n "$boot_volume_uuid"
  assertEquals 0 $?

  run_cmd instance backup_volume ${instance_uuid} $boot_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?


  local backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid"
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
  assertEquals 0 $?

  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  document_pair? backup_object ${backup_obj_uuid} state deleted
  assertEquals 0 $?
}

# PUT $base_uri/volumes/vol-xxxxxx/backup
function test_volume_backup_under_volumes() {
  run_cmd instance show_volumes "${instance_uuid}" | ydump > $last_result_path
  assertEquals 0 $?

  local boot_volume_uuid=$(yfind '0/:uuid:' < $last_result_path)
  test -n "$boot_volume_uuid"
  assertEquals 0 $?

  run_cmd volume backup $boot_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?

  local backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid"
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
  assertEquals 0 $?

  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  document_pair? backup_object ${backup_obj_uuid} state deleted
  assertEquals 0 $?
}

# backup tasks are expected to work solely without any conflictions. this scenario
# can be confirmed by the following steps:
#
#  1. issues two backup tasks at almost same time.
#  2. waits for two of their accomplishments. it can be judged by state having available
#     otherwise the test fails.
function test_multiple_backup_tasks_without_confliction() {
  run_cmd instance show_volumes "${instance_uuid}" | ydump > $last_result_path
  assertEquals 0 $?

  local boot_volume_uuid=$(yfind '0/:uuid:' < $last_result_path)
  test -n "$boot_volume_uuid"
  assertEquals 0 $?

  run_cmd volume backup $boot_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?
cat $last_result_path
  local backup_obj_uuid1=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid1"
  assertEquals 0 $?

  run_cmd volume backup $boot_volume_uuid | ydump > $last_result_path
  assertEquals 0 $?
cat $last_result_path
  local backup_obj_uuid2=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid2"
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${backup_obj_uuid1} state available"
  assertEquals 0 $?
  retry_until "document_pair? backup_object ${backup_obj_uuid2} state available"
  assertEquals 0 $?

  run_cmd backup_object destroy ${backup_obj_uuid1}
  assertEquals 0 $?
  run_cmd backup_object destroy ${backup_obj_uuid2}
  assertEquals 0 $?

  document_pair? backup_object ${backup_obj_uuid1} state deleted
  assertEquals 0 $?
  document_pair? backup_object ${backup_obj_uuid2} state deleted
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
