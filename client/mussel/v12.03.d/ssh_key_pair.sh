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
    public_key=${public_key:-} \
    ) \
   ${base_uri}/${1}s.${format}
}
