#!/bin/bash
#
#
#
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
launch_host_node=${launch_host_node:-hn-demo1}
migration_host_node=${migration_host_node:-hn-demo2}
blank_volume_size=${blank_volume_size:-10}

## hook functions

last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})

  # reset command parameters
  volumes_args=
}

### step

# API test for shared volume instance migration.
#
# 1.  boot shared volume instance.
# 2.  migration the instance.
# 3.  check the process.
# 4.  poweroff the instance.
# 5.  poweron the instance.
# 6.  attach volume to instance.
# 7.  check the attach second volume.
# 8.  detach volume to instance.
# 9.  check the detach second volume.
# 10. terminate the instance.
function test_migration_shared_volume_instance(){
  # boot shared volume instance.
  local host_node_id=${launch_host_node}
  create_instance

  # bind sleep process
  bind_sleep_process
  assertEquals 0 $?

  # sleep process id
  process_id=$(sleep_process_id)
  test -n "${process_id}"
  assertEquals 0 $?
  echo "sleep process id: ${process_id}"

  # migration the instance.
  host_node_id=${migration_host_node} run_cmd instance move ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?

  # check the process.
  new_process_id=$(sleep_process_id)
  test -n "${new_process_id}"
  assertEquals 0 $?
  echo "sleep process id: ${new_process_id}"
  assertEquals ${process_id} ${new_process_id}

  # poweroff the instance.
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  # poweron the instance.
  run_cmd instance poweron ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?

  # wait for network to be ready
  wait_for_network_to_be_ready ${instance_ipaddr}

  # wait for sshd to be ready
  wait_for_sshd_to_be_ready    ${instance_ipaddr}

  # create new blank volume
  volume_uuid=$(volume_size=${blank_volume_size} run_cmd volume create | hash_value uuid)
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # attach volume to instance.
  instance_id=${instance_uuid} run_cmd volume attach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state attached"
  assertEquals 0 $?

  remote_sudo=$(remote_sudo)

  # blank device path 
  blank_dev_path=$(blank_dev_path)
  test -n "${blank_dev_path}"
  assertEquals 0 $?
  test -n "${blank_dev_path}" || return

  # check the attach second volume.
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # detach volume to instance
  instance_id=${instance_uuid} run_cmd volume detach ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state available"
  assertEquals 0 $?

  # check the detach second volume.
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertNotEquals 0 $?

  # delete new blank volume
  run_cmd volume destroy ${volume_uuid}
  retry_until "document_pair? volume ${volume_uuid} state deleted"
  assertEquals 0 $?

  # terminate the instance.
  destroy_instance
}

# API test for shared volume instance with second blank volume migration.
#
# 1. boot shared volume instance with second blank volume.
# 2. migration the instance.
# 3. check the second blank disk.
# 4. check the process.
# 5. poweroff the instance.
# 6. poweron the instance.
# 7. terminate the instance.
function test_migration_shared_volume_instance_with_second_blank_volume(){
  # boot shared volume instance with second blank volume.
  volumes_args="volumes[0][size]=${blank_volume_size} volumes[0][volume_type]=shared"
  local host_node_id=${launch_host_node}
  create_instance

  # second blank volume
  run_cmd instance show_volumes ${instance_uuid} | ydump > ${last_result_path}
  assertEquals 0 $?

  local volume_uuid=$(yfind '1/:uuid:' < ${last_result_path})
  test -n "${volume_uuid}"
  assertEquals 0 $?
  echo ${volume_uuid}

  remote_sudo=$(remote_sudo)

  # blank device path
  blank_dev_path=$(blank_dev_path)
  test -n "${blank_dev_path}"
  assertEquals 0 $?
  test -n "${blank_dev_path}" || return
  echo ${blank_dev_path}

  # check the second blank disk.
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # bind sleep process
  bind_sleep_process
  assertEquals 0 $?

  # sleep process id
  process_id=$(sleep_process_id)
  test -n "${process_id}"
  assertEquals 0 $?
  echo "sleep process id: ${process_id}"

  # migration the instance.
  host_node_id=${migration_host_node} run_cmd instance move ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?

  # check the process.
  new_process_id=$(sleep_process_id)
  test -n "${new_process_id}"
  assertEquals 0 $?
  echo "sleep process id: ${new_process_id}"
  assertEquals ${process_id} ${new_process_id}

  # check the second blank disk.
  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} <<-EOS
	${remote_sudo} lsblk -d ${blank_dev_path}
	EOS
  assertEquals 0 $?

  # poweroff the instance.
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?

  # poweron the instance.
  run_cmd instance poweron ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?

  # terminate the instance.
  destroy_instance
}

## shunit2

. ${shunit2_file}

