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

### create

function test_instance_create_no_opts() {
  local cmd=create

  local ha_enabled=false
  local image_id=wmi-lucid0
  local instance_spec_id=is-demospec
  local network_scheduler=default
  local security_groups=sg-demofgr
  local ssh_key_id=ssh-demo
  local user_data=shunit2

  local opts=""

  local params="
    ha_enabled=${ha_enabled}
    image_id=${image_id}
    instance_spec_id=${instance_spec_id}
    network_scheduler=${network_scheduler}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    user_data=${user_data}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

function test_instance_create_opts() {
  local cmd=create

  local ha_enabled=false
  local image_id=wmi-lucid0
  local instance_spec_id=is-demospec
  local network_scheduler=default
  local security_groups=sg-demofgr
  local ssh_key_id=ssh-demo
  local user_data=shunit2

  local opts="
    --ha-enabled=${ha_enabled}
    --image-id=${image_id}
    --instance-spec-id=${instance_spec_id}
    --network-scheduler=${network_scheduler}
    --security-groups=${security_groups}
    --ssh-key-id=${ssh_key_id}
    --user-data=${user_data}
  "

  local params="
    ha_enabled=${ha_enabled}
    image_id=${image_id}
    instance_spec_id=${instance_spec_id}
    network_scheduler=${network_scheduler}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    user_data=${user_data}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

### reboot

function test_instance_reboot() {
  local cmd=reboot

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### stop

function test_instance_stop() {
  local cmd=stop

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### start

function test_instance_start() {
  local cmd=start

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

## shunit2

. ${shunit2_file}
