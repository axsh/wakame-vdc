# -*-Shell-script-*-
#
# dolphin
#

. ${BASH_SOURCE[0]%/*}/base.sh

function task_show() {
  local namespace=$1 cmd=$2 start_id=$3 

  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${start_id}"      ]] || { echo "[ERROR] 'start_id' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  xquery="limit=1\&start_id=${start_id}"
  call_api -X GET $(base_uri)/${namespace}s?${xquery}
}

function task_create() {
  call_api -X POST -d '$(cat ${message})' \
   $(base_uri)/${namespace}s
}
