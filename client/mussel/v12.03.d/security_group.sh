# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    service_type=${service_type} \
    $(strfile_type "rule") \
    description=${description} \
    display_name=${display_name} \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_update() {
  call_api -X PUT $(urlencode_data \
    $(strfile_type "rule") \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
