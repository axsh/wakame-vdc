#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=network_vif_monitor
declare uuid=i-xxxxxxxx
declare monitor_id=nwm-xxxxxxxx

## functions

## step

### index

function test_network_vif_monitor_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET $(base_uri)/network_vifs/${uuid}/monitors.$(suffix)"
}

### show

function test_network_vif_monitor_show() {
  local cmd=show
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${monitor_id})" \
               "curl -X GET $(base_uri)/network_vifs/${uuid}/monitors/${monitor_id}.$(suffix)"
}

### create

function test_network_vif_monitor_create() {
  local cmd=create

  local enabled=true
  local title=PORT1
  local params="notification_id=mussel port=80"

  local opts=""

  local parameters="
    enabled=${enabled}
    title=${title}
    params[notification_id]=mussel
    params[port]=80
  " 
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X POST $(urlencode_data ${parameters}) $(base_uri)/network_vifs/${uuid}/monitors.$(suffix)"
}

### update

function test_network_vif_monitor_update() {
  local cmd=update

  local enabled=true
  local title=PROCESS1
  local params="notification_id=mussel port=80"

  local opts=""

  local parameters="
    enabled=${enabled}
    title=${title}
    params[notification_id]=mussel
    params[port]=80
  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${monitor_id} ${opts})" \
               "curl -X PUT $(urlencode_data ${parameters}) $(base_uri)/network_vifs/${uuid}/monitors/${monitor_id}.$(suffix)"
}

### destroy

function test_network_vif_monitor_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${monitor_id})" \
               "curl -X DELETE $(base_uri)/network_vifs/${uuid}/monitors/${monitor_id}.$(suffix)"
}

## shunit2

. ${shunit2_file}
