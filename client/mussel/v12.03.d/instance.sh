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
    $(add_param cpu_cores           string) \
    $(add_param display_name        string) \
    $(add_param hostname            string) \
    $(add_param hypervisor          string) \
    $(add_param image_id            string) \
    $(add_param instance_spec_name  string) \
    $(add_param memory_size         string) \
    $(add_param security_groups      array) \
    $(add_param service_type        string) \
    $(add_param ssh_key_id          string) \
    $(add_param user_data          strfile) \
    $(add_param vifs               strfile) \
    $(add_param host_node_id        string) \
    $(add_param ha_enabled          string) \
   ) \
   $(add_args_param volumes) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_backup() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param description  string) \
    $(add_param display_name string) \
    $(add_param is_cacheable string) \
    $(add_param is_public    string) \
    $(add_param all    string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/backup.$(suffix)
}

piped_task_backup() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:image_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

task_show_volumes() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X GET $(base_uri)/${namespace}s/${uuid}/volumes.$(suffix)
}

task_backup_volume() {
  local namespace=$1 cmd=$2 uuid=$3 volume_uuid=$4
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${volume_uuid}" ]] || { echo "[ERROR] 'volume_uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param description  string) \
    $(add_param display_name string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/volumes/${volume_uuid}/backup.$(suffix)
}

task_reboot() {
  cmd_put $*
}

piped_task_reboot() {
  case "${mussel_output_format:-""}" in
    id) tail -n 1 </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

_task_stop() {
  cmd_put $*
}

_task_start() {
  cmd_put $*
}

task_poweroff() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param force string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

piped_task_poweroff() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:instance_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

task_poweron() {
  cmd_put $*
}

piped_task_poweron() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:instance_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

task_move() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param host_node_id string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param display_name        string) \
    $(add_param ssh_key_id          string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
