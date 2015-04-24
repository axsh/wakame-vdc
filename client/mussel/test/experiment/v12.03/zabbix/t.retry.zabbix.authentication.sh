#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_zabbix.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

function after_create_instance() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  vif_uuid=$(run_cmd instance show ${instance_uuid} | ydump | yfind ':vif:/0/:vif_id:')
  auth=$(zabbix_api_authenticate)
}

## step

function test_instance_monitoring_enable() {
  local monitoring="enabled=true"

  run_cmd instance_monitoring set_enable ${instance_uuid}
  assertEquals 0 $?
}

function test_instance_monitoring_enable_for_zabbix() {
  retry_until "zabbix_document_pair? host get /result/0/status 0"
  assertEquals 0 $?
}

function test_delete_zabbix_api_authenticate() {
  delete_sessions
  assertEquals 0 $?
}

function test_retry_zabbix_api_authenticate() {
  local enabled=true
  local title=PING
  local params="notification_id=mussel"

  monitoring_uuid=$(run_cmd network_vif_monitor create ${vif_uuid} | hash_value uuid)
  assertEquals 0 $?

  run_cmd network_vif_monitor show ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_retry_zabbix_api_authenticate_for_zabbix() {
  local item_key="icmpping[{\$IPADRESS1},,,,1000]"

  retry_until "zabbix_document_pair? item get /result/0/status 0"
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}
