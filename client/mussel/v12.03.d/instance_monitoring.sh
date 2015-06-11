# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/filter/${BASH_SOURCE[0]##*/}

task_index() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X GET \
  $(base_uri)/instances/${uuid}/monitoring.yml
}

task_show() {
  local namespace=$1 cmd=$2 uuid=$3 monitor_id=$4
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${monitor_id}"      ]] || { echo "[ERROR] 'monitor_id' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X GET \
  $(base_uri)/instances/${uuid}/monitoring/${monitor_id}.yml
}

task_create() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X POST $(urlencode_data \
    $(add_param enabled string) \
    $(add_param title   string) \
    $(add_param params    hash) \
   ) \
   $(base_uri)/instances/${uuid}/monitoring.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3 monitor_id=$4
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${monitor_id}"      ]] || { echo "[ERROR] 'monitor_id' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param enabled string) \
    $(add_param title   string) \
    $(add_param params    hash) \
   ) \
   $(base_uri)/instances/${uuid}/monitoring/${monitor_id}.$(suffix)
}

task_destroy() {
  local namespace=$1 cmd=$2 uuid=$3 monitor_id=$4
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${monitor_id}"      ]] || { echo "[ERROR] 'monitor_id' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X DELETE \
  $(base_uri)/instances/${uuid}/monitoring/${monitor_id}.$(suffix)
}

task_set_enable() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param monitoring hash) \
   ) \
   $(base_uri)/instances/${uuid}.$(suffix)
}
