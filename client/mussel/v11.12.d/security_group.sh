# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_help() {
  cmd_help ${namespace} "index|show|create|update|destroy"
}

task_create() {
  local description=$3 rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} NAME" >&2; return 1; }

  call_api -X POST $(urlencode_data \
   description=${description} \
   rule=${rule} \
   ) \
   ${base_uri}/${namespace}s.${format}
}

task_update() {
  local description=$3 rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} ID" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
   rule=${rule} \
   ) \
   ${base_uri}/${namespace}s/${description}.${format}
}
