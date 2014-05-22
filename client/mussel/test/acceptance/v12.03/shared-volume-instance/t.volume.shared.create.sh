#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables
volume_size=${volume_size:-10M}
backup_object_id=${backup_object_id:-centos1d64nfs}

## setp

function test_create_new_volume(){
  # create volume
  volume_uuid=$(volume_size=${volume_size} run_cmd volume create | hash_value uuid) 
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?
}

function test_create_new_volume_from_image(){
  # create volume
  volume_uuid=$(backup_object_id=${backup_object_id} run_cmd volume create | hash_value uuid) 
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}

