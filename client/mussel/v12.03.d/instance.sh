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
    $([[ -z "${cpu_cores}"          ]] || echo cpu_cores=${cpu_cores}                  ) \
    $([[ -z "${display_name}"       ]] || echo display_name=${display_name}            ) \
    $([[ -z "${hostname}"           ]] || echo hostname=${hostname}                    ) \
    $([[ -z "${hypervisor}"         ]] || echo hypervisor=${hypervisor}                ) \
    $([[ -z "${image_id}"           ]] || echo image_id=${image_id}                    ) \
    $([[ -z "${instance_spec_name}" ]] || echo instance_spec_name=${instance_spec_name}) \
    $([[ -z "${memory_size}"        ]] || echo memory_size=${memory_size}              ) \
    $([[ -z "${security_groups}"    ]] || echo security_groups[]=${security_groups}    ) \
    $([[ -z "${service_type}"       ]] || echo service_type=${service_type}            ) \
    $([[ -z "${ssh_key_id}"         ]] || echo ssh_key_id=${ssh_key_id}                ) \
    $([[ -z "${user_data}"          ]] || strfile_type "user_data"                     ) \
    $([[ -z "${vifs}"               ]] || strfile_type "vifs"                          ) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_backup() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $([[ -z "${description}"  ]] || echo description=${description}  ) \
    $([[ -z "${display_name}" ]] || echo display_name=${display_name}) \
    $([[ -z "${is_cacheable}" ]] || echo is_cacheable=${is_cacheable}) \
    $([[ -z "${is_public}"    ]] || echo is_public=${is_public}      ) \
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
