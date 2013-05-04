# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  # --state=(running|stopped|terminated|alive)
  if [[ -n "${state}" ]]; then
    xquery="state=${state}"
  fi
  cmd_index $*
}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param allow_list         array) \
    $(add_param balance_algorithm string) \
    $(add_param cookie_name       string) \
    $(add_param description       string) \
    $(add_param display_name      string) \
    $(add_param engine            string) \
    $(add_param httpchk_path      strfile) \
    $(add_param instance_port     string) \
    $(add_param instance_protocol string) \
    $(add_param max_connection    string) \
    $(add_param port               array) \
    $(add_param private_key      strfile) \
    $(add_param protocol           array) \
    $(add_param public_key       strfile) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_poweroff() {
  cmd_put $*
}

task_poweron() {
  cmd_put $*
}

task_register() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param vifs array) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_unregister() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param vifs array) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param allow_list         array) \
    $(add_param balance_algorithm string) \
    $(add_param cookie_name       string) \
    $(add_param display_name      string) \
    $(add_param engine            string) \
    $(add_param httpchk_path      strfile) \
    $(add_param instance_port     string) \
    $(add_param instance_protocol string) \
    $(add_param max_connection    string) \
    $(add_param port               array) \
    $(add_param private_key      strfile) \
    $(add_param protocol           array) \
    $(add_param public_key       strfile) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
