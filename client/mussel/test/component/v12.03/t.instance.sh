#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=instance

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_instance_index_stateless() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?service_type=std"
}

function test_instance_index_stateful() {
  local cmd=index
  local state=running

  assertEquals "$(cli_wrapper ${namespace} ${cmd} --state=${state})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?service_type=std&state=${state}"
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

  local image_id=wmi-lucid5
  local instance_spec_name=is-small
  local security_groups=sg-demofgr
  local ssh_key_id=ssh-demo
  local hypervisor=openvz
  local cpu_cores=1
  local memory_size=1024
  local display_name=shunit2
  local host_name=shunit2
  local vifs="{}"

  local opts=""

  local params="
    --data-urlencode image_id=${image_id}
    --data-urlencode instance_spec_name=${instance_spec_name}
    --data-urlencode security_groups[]=${security_groups}
    --data-urlencode ssh_key_id=${ssh_key_id}
    --data-urlencode hypervisor=${hypervisor}
    --data-urlencode cpu_cores=${cpu_cores}
    --data-urlencode memory_size=${memory_size}
    --data-urlencode display_name=${display_name}
    --data-urlencode host_name=${host_name}
    --data-urlencode vifs=${vifs}
   "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(echo ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_instance_create_opts() {
  local cmd=create

  local image_id=wmi-shunit2
  local instance_spec_name=is-shunit2
  local security_groups=sg-shunit2
  local ssh_key_id=ssh-shunit2
  local hypervisor=shunit2
  local cpu_cores=2
  local memory_size=2048
  local display_name=shunit2
  local host_name=shunit2
  local vifs="{}"

  local opts="
    --image-id=${image_id} \
    --instance-spec-name=${instance_spec_name} \
    --security-groups=${security_groups} \
    --hypervisor=${hypervisor} \
    --cpu-cores=${cpu_cores} \
    --memory-size=${memory_size} \
    --display-name=${display_name} \
    --host-name=${host_name} --vifs=${vifs}
  "

  local params="
    --data-urlencode image_id=${image_id}
    --data-urlencode instance_spec_name=${instance_spec_name}
    --data-urlencode security_groups[]=${security_groups}
    --data-urlencode ssh_key_id=${ssh_key_id}
    --data-urlencode hypervisor=${hypervisor}
    --data-urlencode cpu_cores=${cpu_cores}
    --data-urlencode memory_size=${memory_size}
    --data-urlencode display_name=${display_name}
    --data-urlencode host_name=${host_name}
    --data-urlencode vifs=${vifs}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(echo ${params}) ${base_uri}/${namespace}s.${format}"
}

### xcreate

function test_instance_xcreate() {
  local cmd=xcreate

  local image_id=wmi-shunit2
  local instance_spec_name=is-shunit2
  local security_groups=sg-shunit2
  local ssh_key_id=ssh-shunit2
  local hypervisor=shunit2
  local cpu_cores=2
  local memory_size=2048
  local display_name=shunit2
  local host_name=shunit2

  local MUSSEL_CUSTOM_DATA="
    --data-urlencode image_id=${image_id}
    --data-urlencode instance_spec_name=${instance_spec_name}
    --data-urlencode security_groups[]=${security_groups}
    --data-urlencode ssh_key_id=${ssh_key_id}
    --data-urlencode hypervisor=${hypervisor}
    --data-urlencode cpu_cores=${cpu_cores}
    --data-urlencode memory_size=${memory_size}
    --data-urlencode display_name=${display_name}
    --data-urlencode host_name=${host_name}
    --data-urlencode vifs[eth0][index]=0
    --data-urlencode vifs[eth0][network]=${network_id}
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=${MUSSEL_CUSTOM_DATA} cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(echo ${MUSSEL_CUSTOM_DATA}) ${base_uri}/${namespace}s.${format}"
}

### backup

function test_instance_backup() {
  local cmd=backup

  local description=
  local display_name=
  local is_public=false
  local is_cacheable=false

  local params="
    --data-urlencode description=${description}
    --data-urlencode display_name=${display_name}
    --data-urlencode is_public=${is_public}
    --data-urlencode is_cacheable=${is_cacheable}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(echo ${params}) ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
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

### poweron

function test_instance_poweron() {
  local cmd=poweron

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

### poweroff

function test_instance_poweroff() {
  local cmd=poweroff

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

## shunit2

. ${shunit2_file}
