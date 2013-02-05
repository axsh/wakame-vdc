# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  local description=$3 rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} NAME" >&2; return 1; }

  call_api -X POST $(urlencode_data \
    description=${description} \
    $(strfile_type "rule") \
   ) \
   $(base_uri)/${namespace}s.${DCMGR_RESPONSE_FORMAT}
}

task_update() {
  local description=$3 rule=$4
  [[ -z "${description}" ]] && { echo "${namespace} ${cmd} ID" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(strfile_type "rule") \
   ) \
   $(base_uri)/${namespace}s/${description}.${DCMGR_RESPONSE_FORMAT}
}
