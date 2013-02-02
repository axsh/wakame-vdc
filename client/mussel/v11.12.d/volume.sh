# -*-Shell-script-*-
#
# 11.12
#

task_help() {
  cmd_help ${namespace} "index|show|create|attach|detach|destroy"
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
  volume_size=${3:-10}
  call_api -X POST $(urlencode_data \
    volume_size=${volume_size} \
   ) \
   ${base_uri}/${namespace}s.${format}
}

task_attach() {
  uuid=$3
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [vol-id] [inst-id]" >&2; return 1; }
  call_api -X PUT -d "''" "${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?instance_id"
}

task_detach() {
  uuid=$3
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [vol-id] [inst-id]" >&2; return 1; }
  call_api -X PUT -d "''" "${base_uri}/${namespace}s/${uuid}/${cmd}.${format}?instance_id"
}

task_default() {
  cmd_default $*
}
