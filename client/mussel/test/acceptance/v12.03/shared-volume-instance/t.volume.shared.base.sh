#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables
volume_size=${volume_size:-10}

## setp

function test_create_new_volume(){
  # create volume
  volume_uuid=$(volume_size=${volume_size} run_cmd volume create | hash_value uuid) 
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # delete volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?
}

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

function test_volume_backup_from_new_volume(){
  # create volume
  volume_uuid=$(volume_size=${volume_size} run_cmd volume create | hash_value uuid)
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

