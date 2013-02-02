# -*-Shell-script-*-
#
# 11.12
#

task_help() {
  cmd_help ${namespace} "index|show|create|destroy"
}

task_index() {
  cmd_index $*
}

task_show() {
  cmd_show $*
}

task_create() {
  name=$3
  [[ -z "${name}" ]] && { echo "${namespace} ${cmd} NAME" >&2; return 1; }
  call_api -X POST $(urlencode_data \
    name=${name} \
   ) \
   ${base_uri}/${namespace}s.${format}
}
 
task_destroy() {
  cmd_destroy $*
}

task_default() {
  cmd_default $*
}
