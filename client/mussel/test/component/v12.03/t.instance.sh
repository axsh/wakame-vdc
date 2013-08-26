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
               "curl -X GET $(base_uri)/${namespace}s.$(suffix)?service_type=std"
}

function test_instance_index_stateful() {
  local cmd=index
  local state=running

  assertEquals "$(cli_wrapper ${namespace} ${cmd} --state=${state})" \
               "curl -X GET $(base_uri)/${namespace}s.$(suffix)?service_type=std&state=${state}"
}

### create

function test_instance_create_no_opts() {
  local cmd=create

  local cpu_cores=1
  local display_name=shunit2
  local hostname=shunit2
  local hypervisor=openvz
  local image_id=wmi-lucid5d
  local instance_spec_name=is-small
  local memory_size=1024
  local security_groups=sg-demofgr
  local service_type=std
  local ssh_key_id=ssh-demo
  local user_data=asdf
  local vifs="{}"

  local opts=""

  local params="
    cpu_cores=${cpu_cores}
    display_name=${display_name}
    hostname=${hostname}
    hypervisor=${hypervisor}
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    memory_size=${memory_size}
    security_groups[]=${security_groups}
    service_type=${service_type}
    ssh_key_id=${ssh_key_id}
    user_data=${user_data}
    vifs=${vifs}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

function test_instance_create_opts() {
  local cmd=create

  local cpu_cores=2
  local display_name=shunit2
  local hostname=shunit2
  local hypervisor=shunit2
  local image_id=wmi-shunit2
  local instance_spec_name=is-shunit2
  local memory_size=2048
  local security_groups=sg-shunit2
  local service_type=std
  local ssh_key_id=ssh-shunit2
  local user_data=asdf
  local vifs="{}"

  local opts="
    --cpu-cores=${cpu_cores}
    --display-name=${display_name}
    --host-name=${hostname}
    --hypervisor=${hypervisor}
    --image-id=${image_id}
    --instance-spec-name=${instance_spec_name}
    --memory-size=${memory_size}
    --security-groups=${security_groups}
    --service-type=${service_type}
    --user-data=${user_data}
    --vifs=${vifs}
  "

  local params="
    cpu_cores=${cpu_cores}
    display_name=${display_name}
    hostname=${hostname}
    hypervisor=${hypervisor}
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    memory_size=${memory_size}
    security_groups[]=${security_groups}
    service_type=${service_type}
    ssh_key_id=${ssh_key_id}
    user_data=${user_data}
    vifs=${vifs}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

function test_instance_create_opts_vif_file() {
  local cmd=create

  local cpu_cores=2
  local display_name=shunit2
  local hostname=shunit2
  local hypervisor=shunit2
  local image_id=wmi-shunit2
  local instance_spec_name=is-shunit2
  local memory_size=2048
  local security_groups=sg-shunit2
  local service_type=std
  local ssh_key_id=ssh-shunit2
  local user_data=asdf
  local vifs=${vifs_file}

  local opts="
    --cpu-cores=${cpu_cores}
    --display-name=${display_name}
    --host-name=${hostname}
    --hypervisor=${hypervisor}
    --image-id=${image_id}
    --instance-spec-name=${instance_spec_name}
    --memory-size=${memory_size}
    --security-groups=${security_groups}
    --service-type=${service_type}
    --user-data=${user_data}
    --vifs=${vifs}
  "

  local params="
    cpu_cores=${cpu_cores}
    display_name=${display_name}
    hostname=${hostname}
    hypervisor=${hypervisor}
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    memory_size=${memory_size}
    security_groups[]=${security_groups}
    service_type=${service_type}
    ssh_key_id=${ssh_key_id}
    user_data=${user_data}
    vifs@${vifs}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

function test_instance_create_opts_user_data_file() {
  local cmd=create

  local cpu_cores=2
  local display_name=shunit2
  local hostname=shunit2
  local hypervisor=shunit2
  local image_id=wmi-shunit2
  local instance_spec_name=is-shunit2
  local memory_size=2048
  local security_groups=sg-shunit2
  local service_type=std
  local ssh_key_id=ssh-shunit2
  local user_data=${user_data_file}
  local vifs="{}"

  local opts="
    --cpu-cores=${cpu_cores}
    --display-name=${display_name}
    --host-name=${hostname}
    --hypervisor=${hypervisor}
    --image-id=${image_id}
    --instance-spec-name=${instance_spec_name}
    --memory-size=${memory_size}
    --security-groups=${security_groups}
    --service-type=${service_type}
    --user-data=${user_data}
    --vifs=${vifs}
  "

  local params="
    cpu_cores=${cpu_cores}
    display_name=${display_name}
    hostname=${hostname}
    hypervisor=${hypervisor}
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    memory_size=${memory_size}
    security_groups[]=${security_groups}
    service_type=${service_type}
    ssh_key_id=${ssh_key_id}
    user_data@${user_data}
    vifs=${vifs}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
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
  local hostname=shunit2

  local MUSSEL_CUSTOM_DATA="
    image_id=${image_id}
    instance_spec_name=${instance_spec_name}
    security_groups[]=${security_groups}
    ssh_key_id=${ssh_key_id}
    hypervisor=${hypervisor}
    cpu_cores=${cpu_cores}
    memory_size=${memory_size}
    display_name=${display_name}
    hostname=${hostname}
    vifs[eth0][index]=0
    vifs[eth0][network]=${network_id}
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) $(base_uri)/${namespace}s.$(suffix)"
}

### backup

function test_instance_backup() {
  local cmd=backup

  local description=shunit2
  local display_name=shunit2
  local is_cacheable=false
  local is_public=false

  local params="
    description=${description}
    display_name=${display_name}
    is_cacheable=${is_cacheable}
    is_public=${is_public}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### reboot

function test_instance_reboot() {
  local cmd=reboot

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### stop

function test_instance_stop() {
  local cmd=stop

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### start

function test_instance_start() {
  local cmd=start

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### poweron

function test_instance_poweron() {
  local cmd=poweron

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### poweroff

function test_instance_poweroff() {
  local cmd=poweroff
  local force=true

  local opts="
    --force=${force}
  "

  local params="
    force=${force}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid} ${opts})" \
               "curl -X PUT $(urlencode_data ${params}) $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### show-volumes

function test_instance_show_volumes() {
  assertEquals "curl -X GET $(base_uri)/${namespace}s/${uuid}/volumes.$(suffix)" \
               "$(cli_wrapper ${namespace} 'show_volumes' ${uuid})"
               
}

### backup-volumes

function test_instance_backup_volume() {
  assertEquals "curl -X PUT $(base_uri)/${namespace}s/${uuid}/volumes/vol-xxxxx/backup.$(suffix)" \
               "$(cli_wrapper ${namespace} 'backup_volume' ${uuid} vol-xxxxx)"
               
}

## shunit2

. ${shunit2_file}
