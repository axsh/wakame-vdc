# -*-Shell-script-*-
#
# 11.12
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|create|attach|detach|destroy" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
destroy) cmd_destroy $* ;;
create)
  volume_size=${3:-10}
  call_api -X POST $(urlencode_data \
    volume_size=${volume_size} \
   ) \
   ${base_uri}/${namespace}s.${format}
  ;;
attach|detach)
  uuid=$3
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [vol-id] [inst-id]" >&2; return 1; }
  call_api -X PUT -d "''" \
   "${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?instance_id"
  ;;
*)       cmd_default $* ;;
esac
