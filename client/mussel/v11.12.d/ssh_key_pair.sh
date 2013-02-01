# -*-Shell-script-*-
#
# 11.12
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|create|destroy" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
create)
  name=$3
  [[ -z "${name}" ]] && { echo "${namespace} ${cmd} NAME" >&2; return 1; }
  call_api -X POST \
   --data-urlencode "name=${name}" \
   ${base_uri}/${namespace}s.${format}
  ;;
destroy) cmd_destroy $* ;;
*)       cmd_default $* ;;
esac
