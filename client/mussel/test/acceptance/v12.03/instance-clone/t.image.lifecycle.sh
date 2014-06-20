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

hostname_txt=hostname.txt
ssh_user=${ssh_user:-root}

## functions

## hook functions

last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})
}

### step

function test_backup_instance_and_destroy() {
  create_instance

  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  [[ -n "${instance_ipaddr}" ]]
  assertEquals 0 $?

  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?

  wait_for_sshd_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?

  ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "hostname > ${hostname_txt}; sync"
  assertEquals 0 $?

  ancestral_hostname=$(ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} hostname)
  assertEquals 0 $?

  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"

  run_cmd instance backup "${instance_uuid}" | ydump > $last_result_path
  # ---
  # :instance_id: i-xxx
  # :backup_object_id: bo-xxx
  # :image_id: wmi-xxx
  backup_object_uuid=$(yfind ':backup_object_ids:/0' < $last_result_path)
  new_image_uuid="$(echo "${output}" | hash_value image_id)"

  retry_until "document_pair? backup_object ${backup_object_uuid} state available"
  assertEquals 0 $?

  destroy_instance
  assertEquals 0 $?

  # flush origin instance params
  instance_ipaddr=
}

function test_create_cloned_instance() {
  image_id=${new_image_uuid}
  create_instance
  assertEquals 0 $?
}

#### -> basic logging-in test

function test_get_cloned_instance_ipaddr() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  [[ -n "${instance_ipaddr}" ]]
  assertEquals 0 $?
}

function test_wait_for_network_to_be_ready() {
  if [[ -z "${instance_ipaddr}" ]]; then
    ! :
    assertEquals 0 $?
  else
    wait_for_network_to_be_ready ${instance_ipaddr}
    assertEquals 0 $?
  fi
}

function test_wait_for_sshd_to_be_ready() {
  if [[ -z "${instance_ipaddr}" ]]; then
    ! :
    assertEquals 0 $?
  else
    wait_for_sshd_to_be_ready ${instance_ipaddr}
    assertEquals 0 $?
  fi
}

function test_compare_instance_hostname() {
  if [[ -z "${instance_ipaddr}" ]]; then
    ! :
    assertEquals 0 $?
  else
    assertEquals \
      "$(run_cmd instance show ${instance_uuid} | hash_value hostname)" \
      "$(ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} hostname)"
  fi
}

function test_show_saved_hostname() {
  if [[ -z "${instance_ipaddr}" ]]; then
    ! :
    assertEquals 0 $?
  else
    ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} cat ${hostname_txt}
    assertEquals 0 $?
  fi
}

function test_compare_instance_hostname_with_saved_hostname() {
  if [[ -z "${instance_ipaddr}" ]]; then
    ! :
    assertEquals 0 $?
  else
    assertEquals \
      "${ancestral_hostname}" \
      "$(ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} cat ${hostname_txt})"
  fi
}

#### <- basic logging-in test

function test_destroy_cloned_instance() {
  destroy_instance
  assertEquals 0 $?
}

function test_destroy_cloned_image() {
  run_cmd image destroy ${new_image_uuid}
  assertEquals 0 $?

  retry_until "document_pair? image ${new_image_uuid} state deleted"
  assertEquals 0 $?
}

function test_destroy_cloned_backup_object() {
  run_cmd backup_object destroy ${backup_object_uuid}
  assertEquals 0 $?

  retry_until "document_pair? backup_object ${backup_object_uuid} state deleted"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
