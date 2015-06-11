# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/piped/${BASH_SOURCE[0]##*/}

task_index() {
  # --is-public=(true|false|0|1)
  if [[ -n "${is_public}" ]]; then
    xquery="is_public=${is_public}"
  fi
  # --service-type=(std|lb)
  if [[ -n "${service_type}" ]]; then
    xquery="${xquery}\&service_type=${service_type}"
  fi
  # --state=(alive|alive_with_deleted|available|deleted)
  if [[ -n "${state}" ]]; then
    xquery="${xquery}\&state=${state}"
  fi
  cmd_index $*
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param display_name        string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
