#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_instance_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

### show

function test_instance_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### destroy

function test_instance_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

### create

function test_instance_create_no_opts() {
  local cmd=create

  local image_id=wmi-lucid0
  local instance_spec_id=is-demospec
  local ssh_key_id=ssh-demo
  local security_groups=sg-demofgr
  local ha_enabled=false
  local network_scheduler=default
  local user_data=shunit2

  local opts=""

  local params="
    image_id=${image_id}
    instance_spec_id=${instance_spec_id}
    ssh_key_id=${ssh_key_id}
    security_groups[]=${security_groups}
    ha_enabled=${ha_enabled}
    network_scheduler=${network_scheduler}
    user_data=${user_data}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_instance_create_opts() {
  local cmd=create

  local image_id=wmi-lucid0
  local instance_spec_id=is-demospec
  local ssh_key_id=ssh-demo
  local security_groups=sg-demofgr
  local ha_enabled=false
  local network_scheduler=default
  local user_data=shunit2

  local opts="
    --image-id=${image_id}
    --instance-spec-id=${instance_spec_id}
    --ssh-key-id=${ssh_key_id}
    --security-groups=${security_groups}
    --ha-enabled=${ha_enabled}
    --network-scheduler=${network_scheduler}
    --user-data=${user_data}
  "

  local params="
    image_id=${image_id}
    instance_spec_id=${instance_spec_id}
    ssh_key_id=${ssh_key_id}
    security_groups[]=${security_groups}
    ha_enabled=${ha_enabled}
    network_scheduler=${network_scheduler}
    user_data=${user_data}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

### reboot

function test_instance_reboot() {
  local cmd=reboot

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

### stop

function test_instance_stop() {
  local cmd=stop

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

### start

function test_instance_start() {
  local cmd=start

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

## shunit2

. ${shunit2_file}
