# -*-Shell-script-*-
#
# dolphin
#

. ${BASH_SOURCE[0]%/*}/base.sh

function task_show() {
  echo "[ERROR] no such cmd '${cmd}'" >&2
  exit 1
}

function task_create() {
  call_api -X POST -d '$(cat ${message})' \
   $(base_uri)/${namespace}s
}
