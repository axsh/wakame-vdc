# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  local volume_size=${3:-10}

  call_api -X POST $(urlencode_data \
    volume_size=${volume_size} \
   ) \
   ${DCMGR_BASE_URI}/${namespace}s.${format}
}

task_attach() {
  local uuid=$3 instance_id=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [vol-id] [inst-id]" >&2; return 1; }

  call_api -X PUT -d "''" "${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}?instance_id=${instance_id}"
}

task_detach() {
  local uuid=$3 instance_id=$4
  [[ $# = 4 ]] || { echo "${namespace} ${cmd} [vol-id] [inst-id]" >&2; return 1; }

  call_api -X PUT -d "''" "${DCMGR_BASE_URI}/${namespace}s/${uuid}/${cmd}.${format}?instance_id=${instance_id}"
}
