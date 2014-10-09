# -*-Shell-script-*-
#
# dolphin
#

. ${BASH_SOURCE[0]%/*}/base.sh

function task_index() {
  echo "[ERROR] no such cmd '${cmd}'" >&2
  exit 1
}

function task_show() {
  local namespace=$1 cmd=$2 notification_id=$3

  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${notification_id}"      ]] || { echo "[ERROR] 'notification_id' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X GET $(base_uri)/${namespace}s
}

function task_create() {
  call_api -X POST -d '$(cat ${email})' \
   $(base_uri)/${namespace}s
}

function task_destroy() {
  local namespace=$1 cmd=$2 notification_id=$3

  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${notification_id}"      ]] || { echo "[ERROR] 'notification_id' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X DELETE $(base_uri)/${namespace}s
}
