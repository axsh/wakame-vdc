#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance_monitoring
declare uuid=i-xxxxxxxx
declare monitor_id=imon-xxxxxxxx

## functions

## step

### index

function test_instance_monitoring_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET $(base_uri)/instances/${uuid}/monitoring.$(suffix)"
}

### show

function test_instance_monitoring_show() {
  local cmd=show
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${monitor_id})" \
               "curl -X GET $(base_uri)/instances/${uuid}/monitoring/${monitor_id}.$(suffix)"
}

### create

function test_instance_monitoring_create() {
  local cmd=create

  local enabled=true
  local title=PROCESS1
  local params="notification_id=mussel name=/usr/sbin/httpd"

  local opts=""

  local parameters="
    enabled=${enabled}
    title=${title}
    params[notification_id]=mussel
    params[name]=/usr/sbin/httpd
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X POST $(urlencode_data ${parameters}) $(base_uri)/instances/${uuid}/monitoring.$(suffix)"
}

### update

function test_instance_monitoring_update() {
  local cmd=update

  local enabled=true
  local title=PROCESS1
  local params="notification_id=mussel name=/usr/sbin/httpd"

  local opts=""

  local parameters="
    enabled=${enabled}
    title=${title}
    params[notification_id]=mussel
    params[name]=/usr/sbin/httpd
  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${monitor_id} ${opts})" \
               "curl -X PUT $(urlencode_data ${parameters}) $(base_uri)/instances/${uuid}/monitoring/${monitor_id}.$(suffix)"
}

### destroy

function test_instance_monitoring_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${monitor_id})" \
               "curl -X DELETE $(base_uri)/instances/${uuid}/monitoring/${monitor_id}.$(suffix)"
}

### set_enable

function test_instance_monitoring_set_enable() {
  local cmd=set_enable

  local monitoring=true

  local opts=""

  local parameters="monitoring=${monitoring}"

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${parameters}) $(base_uri)/instances/${uuid}.$(suffix)"
}

## shunit2

. ${shunit2_file}
