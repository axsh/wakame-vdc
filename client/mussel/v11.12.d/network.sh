# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  [[ -z "${gw}"          ]] && { echo "'gw' is empty." >&2; return 1; }
  [[ -z "${network}"     ]] && { echo "'network' is empty." >&2; return 1; }
  [[ -z "${prefix}"      ]] && { echo "'prefix' is empty." >&2; return 1; }
  [[ -z "${description}" ]] && { echo "'description' is empty." >&2; return 1; }

  call_api -X POST $(urlencode_data \
    $(add_param description string) \
    $(add_param gw          string) \
    $(add_param network     string) \
    $(add_param prefix      string) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_reserve() {
  local uuid=$3 ipaddr=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [network-id] [ipaddr]" >&2; return 1; }

  call_api -X PUT "$(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)?ipaddr=${ipaddr}"
}

task_release() {
  local uuid=$3 ipaddr=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [network-id] [ipaddr]" >&2; return 1; }

  call_api -X PUT "$(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)?ipaddr=${ipaddr}"
}

task_add_pool() {
  local uuid=$3 name=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [network-id] [pool-name]" >&2; return 1; }

  call_api -X PUT "$(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)?name=${name}"
}

task_del_pool() {
  local uuid=$3 name=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [network-id] [pool-name]" >&2; return 1; }

  call_api -X PUT "$(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)?name=${name}"
}

task_get_pool() {
  cmd_xget $*
}
