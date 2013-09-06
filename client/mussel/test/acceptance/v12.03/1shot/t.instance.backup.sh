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

function setup_volumes() {
  # boot instance with second volume.
  volumes_args="volumes[0][size]=1G volumes[0][volume_type]=local"
}

last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})
}

### step

function test_backup_second_volume() {
  run_cmd instance show_volumes ${instance_uuid} | ydump > $last_result_path
  assertEquals 0 $?

  local ex_volume_uuid=$(yfind '1/:uuid:' < $last_result_path)
  test -n "$ex_volume_uuid"
  assertEquals 0 $?

  run_cmd instance backup_volume ${instance_uuid} $ex_volume_uuid | ydump > $last_result_path
  assertEquals $? 0

  local backup_obj_uuid=$(yfind ':backup_object_id:' < $last_result_path)
  test -n "$backup_obj_uuid"
  assertEquals $? 0

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
}


## shunit2

. ${shunit2_file}
