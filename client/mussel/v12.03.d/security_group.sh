# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    service_type=${service_type:-std} \
    $(strfile_type "rule") \
    description=${description:-} \
    display_name=${display_name:-} \
   ) \
   $(base_uri)/${namespace}s.${DCMGR_RESPONSE_FORMAT}
}
