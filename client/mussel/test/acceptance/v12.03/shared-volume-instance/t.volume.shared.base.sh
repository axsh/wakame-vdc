#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables
blank_volume_size=${blank_volume_size:-10}

## setp

# API test for create new volume.
#
# 1. create new volume.
# 2. delete the volume.
function test_create_new_volume(){
  # create volume
  volume_uuid=$(volume_size=${blank_volume_size} run_cmd volume create | hash_value uuid) 
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

# API test for create new volume from image.
#
# 1. create new volume.
# 2. delete the volume.
function test_create_new_volume_from_image(){
  # image show
  backup_obj_uuid=$(run_cmd image show ${image_id} | hash_value backup_object_id)

  # create volume
  volume_uuid=$(backup_object_id=${backup_obj_uuid} run_cmd volume create | hash_value uuid) 
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

# API test for volume backup from new volume.
#
# 1. create new volume.
# 2. create backup object from new volume.
# 3. delete the backup object.
# 4. delete the volume.
function test_volume_backup_from_new_volume(){
  # create volume
  volume_uuid=$(volume_size=${blank_volume_size} run_cmd volume create | hash_value uuid)
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # create backup object from new volume
  backup_obj_uuid=$(run_cmd volume backup ${volume_uuid} | hash_value backup_object_id)
  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
  assertEquals 0 $?

  # delete backup_object
  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

# API test for volume backup volume from image.
#
# 1. create new volume from image.
# 2. create backup object from image.
# 3. delete the backup object.
# 4. delete the volume.
function test_volume_backup_from_image(){
  # image show
  backup_obj_uuid=$(run_cmd image show ${image_id} | hash_value backup_object_id)

  # create volume
  volume_uuid=$(backup_object_id=${backup_obj_uuid} run_cmd volume create | hash_value uuid)
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # create backup object from image
  backup_obj_uuid=$(run_cmd volume backup ${volume_uuid} | hash_value backup_object_id)
  retry_until "document_pair? backup_object ${backup_obj_uuid} state available"
  assertEquals 0 $?

  # delete backup_object
  run_cmd backup_object destroy ${backup_obj_uuid}
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}

