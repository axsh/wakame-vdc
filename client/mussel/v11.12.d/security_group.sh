# -*-Shell-script-*-
#
# 11.12
#

task_help() {
 cmd_help ${namespace} "index|show|create|update|destroy"
}

task_index() {
  cmd_index $*
}

task_show() {
  cmd_show $*
}

task_destroy() {
  cmd_destroy $*
}

task_create() {
  description=$3
  rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} NAME" >&2; return 1; }
  call_api -X POST $(urlencode_data \
   description=${description} \
   rule=${rule} \
   ) \
   ${base_uri}/${namespace}s.${format}
}

task_update() {
  description=$3
  rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} ID" >&2; return 1; }
  call_api -X PUT $(urlencode_data \
   rule=${rule} \
   ) \
   ${base_uri}/${namespace}s/${description}.${format}
}

task_default() {
  cmd_default $*
}
