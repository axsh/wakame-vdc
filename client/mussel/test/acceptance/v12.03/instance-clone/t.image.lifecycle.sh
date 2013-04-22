#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

description=${description:-}
display_name=${display_name:-}
is_cacheable=${is_cacheable:-}
is_public=${is_public:-}

backup_object_uuid=
new_image_uuid=

## functions

### step

function test_backup_instance_and_destroy() {
  create_instance
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"

  output="$(run_cmd instance backup ${instance_uuid})"
  # ---
  # :instance_id: i-xxx
  # :backup_object_id: bo-xxx
  # :image_id: wmi-xxx
  backup_object_uuid="$(echo "${output}" | hash_value backup_object_id)"
  new_image_uuid="$(echo "${output}" | hash_value image_id)"

  retry_until "document_pair? backup_object ${backup_object_uuid} state available"
  assertEquals $? 0

  destroy_instance
  assertEquals $? 0

  # flush origin instance params
  instance_ipaddr=
}

function test_create_cloned_instance() {
  image_id=${new_image_uuid}
  create_instance
  assertEquals $? 0
}

#### -> basic logging-in test

function test_get_cloned_instance_ipaddr() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  assertEquals $? 0
}

function test_wait_for_network_to_be_ready() {
  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

function test_wait_for_sshd_to_be_ready() {
  wait_for_sshd_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

function test_compare_instance_hostname() {
  assertEquals \
    "$(run_cmd instance show ${instance_uuid} | hash_value hostname)" \
    "$(ssh root@${instance_ipaddr} -i ${ssh_key_pair_path} hostname)"
}

#### <- basic logging-in test

function test_destroy_cloned_instance() {
  destroy_instance
  assertEquals $? 0
}

function test_destroy_cloned_image() {
  run_cmd image destroy ${new_image_uuid}
  assertEquals $? 0

  retry_until "document_pair? image ${new_image_uuid} state deleted"
  assertEquals $? 0
}

function test_destroy_cloned_backup_object() {
  run_cmd backup_object destroy ${backup_object_uuid}
  assertEquals $? 0

  retry_until "document_pair? backup_object ${backup_object_uuid} state deleted"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
