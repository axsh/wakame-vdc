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

## functions

### step

function test_local_volume_disk_full() {
  remote_sudo=$(remote_sudo)

  # blank device path
  blank_dev_path=$(blank_dev_path)
  [[ -n "${blank_dev_path}" ]]
  assertEquals 0 $?
  [[ -n "${blank_dev_path}" ]] || return

  # format
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	time ${remote_sudo} mkfs.ext3 -F -I 128 ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # mount
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} mount ${blank_dev_path} /mnt
	EOS
  assertEquals 0 $?

  # disk-usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # disk-full
  # dd command will be failed after filling random data
  echo ... use disk usage 100%
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	time ${remote_sudo} dd if=/dev/urandom of=/mnt/test.data
	EOS
  assertNotEquals 0 $?

  # disk-usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # umount
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} umount /mnt
	EOS
  assertEquals 0 $?

  # disk-usage
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	df -P -h
	EOS
  assertEquals 0 $?

  # debug
  echo "> ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path}"
  interactive_suspend_test
}

last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})
}

function test_backup_disk_full_volume() {
  run_cmd instance poweroff ${instance_uuid}
  retry_until "document_pair? instance ${instance_uuid} state halted"

  run_cmd instance show_volumes "${instance_uuid}"| ydump > $last_result_path
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

## shunit2

. ${shunit2_file}
