# -*-Shell-script-*-
#
# 11.12
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|create|destroy" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
destroy) cmd_destroy $* ;;
create)
  gw=${gw}
  prefix=${prefix}
  description=${description}

  [[ -z "${gw}"         ]] && { echo "'gw' is empty." >&2; return 1; }
  [[ -z "${network}"    ]] && { echo "'network' is empty." >&2; return 1; }
  [[ -z "${prefix}"     ]] && { echo "'prefix' is empty." >&2; return 1; }
  [[ -z "${description}"]] && { echo "'description' is empty." >&2; return 1; }
  call_api -X POST \
   --data-urlencode "gw=${gw}" \
   --data-urlencode "network=${network}" \
   --data-urlencode "prefix=${prefix}"  \
   --data-urlencode "description=${description}" \
   ${base_uri}/${namespace}s.${format}
  ;;
reserve|release)
  uuid=$3
  ipaddr=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [network-id] [ipaddr]" >&2; return 1; }
  call_api -X PUT -d "''" \
   "${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?ipaddr=${ipaddr}"
  ;;
add_pool|del_pool)
  uuid=$3
  name=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [network-id] [pool-name]" >&2; return 1; }
  call_api -X PUT -d "''" \
   "${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?name=${name}"
  ;;
get_pool)
  cmd_xget $*
  ;;
*)       cmd_default $* ;;
esac
