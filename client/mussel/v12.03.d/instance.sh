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
    image_id=${image_id} \
    instance_spec_name=${instance_spec_name}  \
    security_groups[]=${security_groups} \
    ssh_key_id=${ssh_key_id} \
    hypervisor=${hypervisor} \
    cpu_cores=${cpu_cores} \
    memory_size=${memory_size} \
    display_name=${display_name} \
    hostname=${hostname} \
    $(strfile_type "vifs") \
    $(strfile_type "user_data") \
    service_type=${service_type} \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_backup() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    description=${description} \
    display_name=${display_name} \
    is_public=${is_public} \
    is_cacheable=${is_cacheable} \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
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
