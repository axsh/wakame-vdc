# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/filter/${BASH_SOURCE[0]##*/}

task_show_external_ip() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X GET $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)
}

task_add_security_group() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  call_api -X PUT $(urlencode_data \
    $(add_param security_group_id string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/add_security_group.$(suffix)
}

task_remove_security_group() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  call_api -X PUT $(urlencode_data \
    $(add_param security_group_id string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/remove_security_group.$(suffix)
}

task_attach_external_ip() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  call_api -X POST $(urlencode_data \
    $(add_param ip_handle_id string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)
}

task_detach_external_ip() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  call_api -X DELETE $(urlencode_data \
    $(add_param ip_handle_id string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)
}
