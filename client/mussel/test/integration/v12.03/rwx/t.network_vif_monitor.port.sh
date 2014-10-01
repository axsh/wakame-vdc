#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_single.sh

## variables

## functions

function needs_vif() { true; }
function needs_secg() { needless_secg; }

function after_create_instance() {
  vif_uuid=$(run_cmd instance show ${instance_uuid} | ydump | yfind ':vif:/0/:vif_id:')
}

## step

function test_instance_monitoring_enable() {
  local monitoring="enable=true"

  run_cmd instance_monitoring set_enable ${instance_uuid}
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

function test_network_vif_monitor_update() {
  local enabled=false

  run_cmd network_vif_monitor update ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?

  run_cmd network_vif_monitor show ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

function test_network_vif_monitor_destroy() {
  run_cmd network_vif_monitor destroy ${vif_uuid} ${monitoring_uuid}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
