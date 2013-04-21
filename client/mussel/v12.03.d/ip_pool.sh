# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  call_api -X GET $(base_uri)/${namespace}s.$(suffix)
}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param dc_networks   array) \
    $(add_param display_name  string) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_ip_handles() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X DELETE $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_acquire() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X PUT $(urlencode_data \
    $(add_param network_id  string) \
   ) \
  $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_release() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X PUT $(urlencode_data \
    $(add_param ip_handle_id  string) \
   ) \
  $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}
