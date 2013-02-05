# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    description=${description:-} \
    display_name=${display_name:-} \
    download_once=${download_once:-} \
    $(strfile_type "public_key") \
   ) \
   ${DCMGR_BASE_URI}/${namespace}s.${DCMGR_RESPONSE_FORMAT}
}
