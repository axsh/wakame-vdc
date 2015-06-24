#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_alarm.sh

## variables
params="tag=var.log.messages match_pattern=error"
alarm_actions="notification_type=dolphin notification_id=1 notification_message_type=log"

## functions

### step

function test_generate_file_for_monitoring_log() {
  create_instance
  assertEquals 0 $?

  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals 0 $?

  sleep ${sleep_sec}

  ssh -t ${$host_ssh_user}@${host_ipaddr} -i ${host_ssh_key_pair_path} <<-EOS
	cat /var/lib/wakame-vdc/fluent.conf | grep ${alarm_uuid}
	EOS
  assertEquals 0 $?

  destroy_instance
  assertEquals 0 $?
}

function test_destroy_alarm_after_instance_terminated() {
  create_instance
  assertEquals 0 $?

  alarm_uuid=$(resource_id=${instance_uuid} run_cmd alarm create | hash_value uuid)
  assertEquals 0 $?

  destroy_instance
  assertEquals 0 $?

  alarm_deleted_at=$(run_cmd alarm show ${alarm_uuid} | yaml_find_first deleted_at)
  assertNotNull "alarm_deleted_at should not be null" "${alarm_deleted_at}"
}

## shunit2

. ${shunit2_file}

