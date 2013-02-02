# -*-Shell-script-*-
#
# 12.03
#

task_help() {
  cmd_help ${namespace} "index|show|create|xcreate|destroy|reboot|stop|start|poweroff|poweron"
}

task_index() {
  # --state=(running|stopped|terminated|alive)
  xquery="service_type=std"
  if [[ -n "${state}" ]]; then
    xquery="${xquery}\&state=${state}"
  fi
  cmd_index $*
}

task_show() {
  cmd_show $*
}

task_destroy() {
  cmd_destroy $*
}

task_create() {
  #
  image_id=${image_id:-wmi-lucid5}
  instance_spec_name=${instance_spec_name:-is-small}
  security_groups=${security_groups:-sg-demofgr}
  ssh_key_id=${ssh_key_id:-ssh-demo}
  hypervisor=${hypervisor:-openvz}
  cpu_cores=${cpu_cores:-1}
  memory_size=${memory_size:-1024}
  vifs=${vifs:-\{\}}
  #
  display_name=${display_name:-}
  host_name=${host_name:-}

  call_api -X POST $(urlencode_data \
    image_id=${image_id} \
    instance_spec_name=${instance_spec_name}  \
    security_groups[]=${security_groups} \
    ssh_key_id=${ssh_key_id} \
    hypervisor=${hypervisor} \
    cpu_cores=${cpu_cores} \
    memory_size=${memory_size} \
    display_name=${display_name} \
    host_name=${host_name} \
    vifs=${vifs} \
   ) \
   ${base_uri}/${namespace}s.${format}
}

task_xcreate() {
  cmd_xcreate ${namespace}
}

task_backup() {
  uuid=$3
  #
  is_public=${is_public:-false}
  is_cacheable=${is_cacheable:-false}
  #
  description=${description:-}

  call_api -X PUT $(urlencode_data \
    description=${description} \
    display_name=${display_name} \
    is_public=${is_public} \
    is_cacheable=${is_cacheable} \
   ) \
   ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_reboot() {
  uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_stop() {
  uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_start() {
  uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_poweroff() {
  uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_poweron() {
  uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_default() {
  cmd_default $*
}
