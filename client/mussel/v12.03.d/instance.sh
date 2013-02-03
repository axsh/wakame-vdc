# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  # --state=(running|stopped|terminated|alive)
  xquery="service_type=std"
  if [[ -n "${state}" ]]; then
    xquery="${xquery}\&state=${state}"
  fi
  cmd_index $*
}

task_create() {
  call_api -X POST $(urlencode_data \
    image_id=${image_id:-wmi-lucid5} \
    instance_spec_name=${instance_spec_name:-is-small}  \
    security_groups[]=${security_groups:-sg-demofgr} \
    ssh_key_id=${ssh_key_id:-ssh-demo} \
    hypervisor=${hypervisor:-openvz} \
    cpu_cores=${cpu_cores:-1} \
    memory_size=${memory_size:-1024} \
    display_name=${display_name} \
    host_name=${host_name} \
    vifs=${vifs:-\{\}} \
   ) \
   ${base_uri}/${namespace}s.${format}
}

task_backup() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}" ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    description=${description} \
    display_name=${display_name} \
    is_public=${is_public:-false} \
    is_cacheable=${is_cacheable:-false} \
   ) \
   ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_reboot() {
  cmd_put $*
}

task_stop() {
  cmd_put $*
}

task_start() {
  cmd_put $*
}

task_poweroff() {
  cmd_put $*
}

task_poweron() {
  cmd_put $*
}
