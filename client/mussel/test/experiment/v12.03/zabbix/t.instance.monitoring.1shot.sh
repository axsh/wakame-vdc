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

function test_instance_monitoring_create() {
  local enabled=true
  local title=PROCESS1
  local params="notification_id=mussel name=/usr/sbin/httpd"

  monitoring_uuid=$(run_cmd instance_monitoring create ${instance_uuid} | hash_value uuid)
  assertEquals 0 $?

  run_cmd instance_monitoring show ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_instance_monitoring_create_for_zabbix() {
  local item_key="proc.num[,,,{\$PROCESS1}]"

  retry_until "zabbix_document_pair? item get /result/0/status 0"
  assertEquals 0 $?
}

function test_instance_monitoring_update() {
  local enabled=false

  run_cmd instance_monitoring update ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?

  run_cmd instance_monitoring show ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_instance_monitoring_update_for_zabbix() {
  local item_key="proc.num[,,,{\$PROCESS1}]"

  retry_until "zabbix_document_pair? item get /result/0/status 1"
  assertEquals 0 $?
}

function test_instance_monitoring_destroy() {
  run_cmd instance_monitoring destroy ${instance_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_network_vif_monitor_create() {
  local enabled=true
  local title=PORT1
  local params="notification_id=mussel port=80"

  monitoring_uuid=$(run_cmd network_vif_monitor create ${vif_uuid} | hash_value uuid)
  assertEquals 0 $?

  run_cmd network_vif_monitor show ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_network_vif_monitor_create_for_zabbix() {
  local item_key="tcp,{\$PORT1}"

  retry_until "zabbix_document_pair? item get /result/0/status 0"
  assertEquals 0 $?
}

function test_network_vif_monitor_update() {
  local enabled=false

  run_cmd network_vif_monitor update ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?

  run_cmd network_vif_monitor show ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_network_vif_monitor_update_for_zabbix() {
  local item_key="tcp,{\$PORT1}"

  retry_until "zabbix_document_pair? item get /result/0/status 1"
  assertEquals 0 $?
}

function test_network_vif_monitor_destroy() {
  run_cmd network_vif_monitor destroy ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_retry_zabbix_api_authenticate() {
  delete_sessions
  assertEquals 0 $?

  local enabled=true
  local title=PING
  local params="notification_id=mussel"

  monitoring_uuid=$(run_cmd network_vif_monitor create ${vif_uuid} | hash_value uuid)
  assertEquals 0 $?

  run_cmd network_vif_monitor show ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_retry_zabbix_api_authenticate_for_zabbix() {
  auth=$(zabbix_api_authenticate)

  local item_key="icmpping[{\$IPADRESS1},,,,1000]"

  retry_until "zabbix_document_pair? item get /result/0/status 0"
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}
