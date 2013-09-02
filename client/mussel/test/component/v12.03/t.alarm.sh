#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=alarm

## index

function test_alarm_index() {
  local cmd=index

  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET $(base_uri)/${namespace}s.$(suffix)"
}

## create

function test_log_alarm_create_no_opts() {
  local cmd=create

  local resource_id=i-demo0001
  local metric_name=log
  local notification_periods=60
  local params="tag=var.log.messages match_pattern=error"

  local opts=""

  local parameters="
    resource_id=${resource_id}
    metric_name=${metric_name}
    notification_periods=${notification_periods}
    params=${params}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data \
                  $(add_param resource_id          string) \
                  $(add_param metric_name          string) \
                  $(add_param notification_periods string) \
                  $(add_param params                 hash) \
                ) $(base_uri)/${namespace}s.$(suffix)"
}

function test_resource_alarm_create_no_opts() {
  local cmd=create

  local resource_id=i-demo0001
  local metric_name=cpu.usage
  local evaluation_periods=60
  local params="threshold=60 comparison_operator=ge"

  local opts=""

  local parameters="
    resource_id=${resource_id}
    metric_name=${metric_name}
    evaluation_periods=${evaluation_periods}
    params=${params}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data \
                  $(add_param resource_id          string) \
                  $(add_param metric_name          string) \
                  $(add_param evaluation_periods string) \
                  $(add_param params                 hash) \
                ) $(base_uri)/${namespace}s.$(suffix)"
}

## update

function test_log_alarm_update_no_opts() {
  local cmd=update
  local uuid=alm-demo

  local enabled=1
  local notification_periods=60
  local params="tag=var.log.messages match_pattern=error"

  local opts=""

  local parameters="
    enabled=${enabled}
    notification_periods=${notification_periods}
    params=${params}

  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${parameters}) $(base_uri)/${namespace}s/${uuid}.$(suffix)"
  
}

function test_resource_alarm_update_no_opts() {
  local cmd=update
  local uuid=alm-demo

  local enabled=1
  local evaluation_periods=60
  local params="threshold=60 comparison_operator=ge"

  local opts=""

  local parameters="
    enabled=${enabled}
    evaluation_periods=${evaluation_periods}
    params=${params}

  "
  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${parameters}) $(base_uri)/${namespace}s/${uuid}.$(suffix)"
  
}

## shunit2

. ${shunit2_file}
