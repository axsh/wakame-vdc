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

## functions

function after_create_instance() {
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
}

### step

# GET $base_uri/instances/i-xxxxx/volumes
function test_get_volume() {
  run_cmd instance show_volumes "${instance_uuid}" > /dev/null
  assertEquals $? 0
}

# PUT $base_uri/instances/i-xxxxx/volumes/vol-xxxxxx
function test_backup_volume() {
  local result_path=$(mktemp)
  run_cmd instance show_volumes "${instance_uuid}" > $result_path
  assertEquals $? 0
  
  local boot_volume_uuid=$(yaml_find_first 'uuid' < $result_path)
  test -n "$boot_volume_uuid"
  assertEquals $? 0

  run_cmd instance backup_volume ${instance_uuid} $boot_volume_uuid > $result_path
  assertEquals $? 0


  local backup_obj_uuid=$(yaml_find_first 'backup_object_id' < $result_path)
  test -n "$backup_obj_uuid"
  assertEquals $? 0

  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
  rm -f $result_path
}

## shunit2

. ${shunit2_file}
