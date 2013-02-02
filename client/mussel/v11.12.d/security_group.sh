# -*-Shell-script-*-
#
# 11.12
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|create|update|destroy" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
destroy) cmd_destroy $* ;;
create)
  description=$3
  rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} NAME" >&2; return 1; }
  call_api -X POST $(urlencode_data \
   description=${description} \
   rule=${rule} \
   ) \
   ${base_uri}/${namespace}s.${format}
  ;;
update)
  description=$3
  rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} ID" >&2; return 1; }
  call_api -X PUT $(urlencode_data \
   rule=${rule} \
   ) \
   ${base_uri}/${namespace}s/${description}.${format}
  ;;
*)       cmd_default $* ;;
esac
