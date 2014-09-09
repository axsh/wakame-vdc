#!/bin/bash
#
# requires:
#  bash
#  cat, ssh, chmod
#

## include files
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_log_alarm.sh

## variables
params="tag=var.log.messages match_pattern=error"
alarm_actions="notification_type=dolphin notification_id=mussel notification_message_type=log"

## functions

function setUp() {
  load_instance_file
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)  
}

## step

# API test for log alarm setup.
function test_log_alarm_setup() {
  resource_id=${instance_uuid} run_cmd alarm create
  assertEquals 0 $?
}

# setup user VM for log monitoring
#
# 1. setup td-agent.conf to user VM.
# 2. change permission /var/log/messages
# 3. restart td-agent to user VM.
# 4. check /var/log/td-agent/td-agent.log.
function test_log_alarm_setup_to_user_vm() {
  render_tdagent_conf \
  | ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "sudo bash -c 'tee /etc/td-agent/td-agent.conf'"
  assertEquals 0 $?

  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "sudo chmod 644 /var/log/messages"
  assertEquals 0 $?

  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "sudo /etc/init.d/td-agent restart"
  assertEquals 0 $?

  ssh -t ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "sudo grep 'following tail of /var/log/messages' /var/log/td-agent/td-agent.log"
  assertEquals 0 $?

}

## shunit2
. ${shunit2_file}

