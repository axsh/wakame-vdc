#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=instance
declare vifs_file=${BASH_SOURCE[0]%/*}/vifs_file.$$.txt
declare user_data_file=${BASH_SOURCE[0]%/*}/user_data_file.$$.txt

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf

  cat <<-EOS > ${vifs_file}
	{}
	EOS
  cat <<-EOS > ${user_data_file}
	USER_DATA=foobar
	EOS
}

function tearDown() {
  rm -f ${vifs_file}
  rm -f ${user_data_file}
}

### index

function test_instance_index_stateless() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${DCMGR_BASE_URI}/${namespace}s.${format}?service_type=std"
}

function test_instance_index_stateful() {
  local cmd=index
  local state=running

  assertEquals "$(cli_wrapper ${namespace} ${cmd} --state=${state})" \
               "curl -X GET ${DCMGR_BASE_URI}/${namespace}s.${format}?service_type=std&state=${state}"
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
  local user_data=asdf
  local service_type=std

  local opts=""

  local params="
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    hypervisor=${hypervisor}
    cpu_cores=${cpu_cores}
    memory_size=${memory_size}
    display_name=${display_name}
    host_name=${host_name}
    vifs=${vifs}
    user_data=${user_data}
    service_type=${service_type}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${DCMGR_BASE_URI}/${namespace}s.${format}"
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
  local user_data=asdf
  local service_type=std

  local opts="
    --image-id=${image_id}
    --instance-spec-name=${instance_spec_name}
    --security-groups=${security_groups}
    --hypervisor=${hypervisor}
    --cpu-cores=${cpu_cores}
    --memory-size=${memory_size}
    --display-name=${display_name}
    --host-name=${host_name}
    --vifs=${vifs}
    --user-data=${user_data}
    --service-type=${service_type}
  "

  local params="
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    hypervisor=${hypervisor}
    cpu_cores=${cpu_cores}
    memory_size=${memory_size}
    display_name=${display_name}
    host_name=${host_name}
    vifs=${vifs}
    user_data=${user_data}
    service_type=${service_type}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${DCMGR_BASE_URI}/${namespace}s.${format}"
}

function test_instance_create_opts_vif_file() {
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
  local vifs=${vifs_file}
  local user_data=asdf
  local service_type=std

  local opts="
    --image-id=${image_id}
    --instance-spec-name=${instance_spec_name}
    --security-groups=${security_groups}
    --hypervisor=${hypervisor}
    --cpu-cores=${cpu_cores}
    --memory-size=${memory_size}
    --display-name=${display_name}
    --host-name=${host_name}
    --vifs=${vifs}
    --user-data=${user_data}
    --service-type=${service_type}
  "

  local params="
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    hypervisor=${hypervisor}
    cpu_cores=${cpu_cores}
    memory_size=${memory_size}
    display_name=${display_name}
    host_name=${host_name}
    vifs@${vifs}
    user_data=${user_data}
    service_type=${service_type}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${DCMGR_BASE_URI}/${namespace}s.${format}"
}

function test_instance_create_opts_user_data_file() {
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
  local user_data=${user_data_file}
  local service_type=std

  local opts="
    --image-id=${image_id}
    --instance-spec-name=${instance_spec_name}
    --security-groups=${security_groups}
    --hypervisor=${hypervisor}
    --cpu-cores=${cpu_cores}
    --memory-size=${memory_size}
    --display-name=${display_name}
    --host-name=${host_name}
    --vifs=${vifs}
    --user-data=${user_data}
    --service-type=${service_type}
  "

  local params="
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    hypervisor=${hypervisor}
    cpu_cores=${cpu_cores}
    memory_size=${memory_size}
    display_name=${display_name}
    host_name=${host_name}
    vifs=${vifs}
    user_data@${user_data}
    service_type=${service_type}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${DCMGR_BASE_URI}/${namespace}s.${format}"
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
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    hypervisor=${hypervisor}
    cpu_cores=${cpu_cores}
    memory_size=${memory_size}
    display_name=${display_name}
    host_name=${host_name}
    vifs[eth0][index]=0
    vifs[eth0][network]=${network_id}
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) ${DCMGR_BASE_URI}/${namespace}s.${format}"
}

### backup

function test_instance_backup() {
  local cmd=backup

  local description=
  local display_name=
  local is_public=false
  local is_cacheable=false

  local params="
    description=${description}
    display_name=${display_name}
    is_public=${is_public}
    is_cacheable=${is_cacheable}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(urlencode_data ${params}) ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"
}

### reboot

function test_instance_reboot() {
  local cmd=reboot

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"
}

### stop

function test_instance_stop() {
  local cmd=stop

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"
}

### start

function test_instance_start() {
  local cmd=start

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"
}

### poweron

function test_instance_poweron() {
  local cmd=poweron

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"
}

### poweroff

function test_instance_poweroff() {
  local cmd=poweroff

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}"
}

## shunit2

. ${shunit2_file}
